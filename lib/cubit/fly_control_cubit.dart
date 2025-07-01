// lib/cubit/fly_control_cubit.dart (Phiên bản tối ưu hóa kết hợp)
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../api/communicate_service.dart';
import 'fly_control_state.dart';

class FlyControlCubit extends Cubit<FlyControlState> {
  final CommunicationService _communicationService;
  StreamSubscription? _pwmDataSubscription;

  int _ch1Value = 1000;
  int _ch2Value = 1500;
  int _ch3Value = 1500;
  int _ch4Value = 1500;
  int _angleValue = 90;

  // Biến cho Throttling
  Timer? _sendTimer;
  static const Duration _sendInterval = Duration(milliseconds: 50); // Gửi tối đa 20 lần/giây

  // Biến cho kiểm tra thay đổi
  int _lastSentCh1 = 1000;
  int _lastSentCh2 = 1500;
  int _lastSentCh3 = 1500;
  int _lastSentCh4 = 1500;
  int _lastSentCh5 = 90;
  static const int _pwmChangeThreshold = 2; // Chỉ gửi nếu thay đổi >= 2 PWM units
  static const int _angleChangeThreshold = 1; // Chỉ gửi nếu thay đổi >= 1 độ

  FlyControlCubit(this._communicationService) : super(const FlyControlState()) {
    _pwmDataSubscription = _communicationService.pwmDataStream.listen(
          (data) {
        // Xử lý phản hồi nếu cần
      },
      onError: (error) {
        emit(state.copyWith(connectionStatus: ConnectionStatus.error));
        print("CUBIT: Lỗi WebSocket từ Service: $error");
      },
      onDone: () {
        emit(state.copyWith(connectionStatus: ConnectionStatus.disconnected));
        print("CUBIT: WebSocket đã ngắt kết nối.");
      },
    );
  }

  int _mapJoystickAxisToPwm(double axisValue, {int center = 1500, int range = 500}) {
    return (center + (axisValue * range)).round().clamp(1000, 2000);
  }

  // Cập nhật các giá trị kênh PWM
  void updateLeftJoystick(double x, double y) {
    emit(state.copyWith(leftStickX: x, leftStickY: y));
    _ch1Value = _mapJoystickAxisToPwm(y); // Throttle
    _ch2Value = _mapJoystickAxisToPwm(x); // Yaw
    _schedulePwmSend(); // Chỉ lên lịch gửi, không gửi ngay lập tức
  }

  void updateRightJoystick(double x, double y) {
    emit(state.copyWith(rightStickX: x, rightStickY: y));
    _ch3Value = _mapJoystickAxisToPwm(y); // Pitch
    _ch4Value = _mapJoystickAxisToPwm(x); // Roll
    _schedulePwmSend(); // Chỉ lên lịch gửi
  }

  void updateSwitch(int index, bool value) {
    final newSwitchValues = List<bool>.from(state.switchValues);
    newSwitchValues[index] = value;
    emit(state.copyWith(switchValues: newSwitchValues));

    if (index == 0) {
      if (value) {
        _ch1Value = 1100;
        print("CUBIT: Công tắc 1 BẬT (Set Throttle to 1100)");
      } else {
        _ch1Value = 1000;
        print("CUBIT: Công tắc 1 TẮT (Set Throttle to 1000)");
      }
      _schedulePwmSend(); // Lên lịch gửi sau khi thay đổi công tắc
    } else if (index == 1) {
      print("CUBIT: Công tắc Mode ${value ? 'BẬT' : 'TẮT'}");
      _schedulePwmSend(); // Cũng lên lịch gửi nếu công tắc mode thay đổi
    } else if (index == 2) {
      print("CUBIT: Công tắc Aux 1 ${value ? 'BẬT' : 'TẮT'}");
      // Gửi thông tin về công tắc Aux 1 qua WebSocket với route /toggle
      // Công tắc này có thể gửi riêng vì nó là một lệnh toggle, không phải PWM liên tục
      _communicationService.sendToggleData(
        t1: newSwitchValues[0],
        t2: newSwitchValues[1],
        t3: newSwitchValues[2],
      );
    }
  }

  void updateAngleSlider(double value) {
    _angleValue = value.round().clamp(0, 180);
    emit(state.copyWith(sliderValue: value / 180));
    _schedulePwmSend(); // Chỉ lên lịch gửi
  }

  // Hàm này sẽ được gọi từ các hàm updateJoystick/Slider/Switch
  void _schedulePwmSend() {
    // Nếu có timer đang chạy, không làm gì cả.
    // Nếu không, tạo một timer mới để gửi dữ liệu sau _sendInterval.
    if (_sendTimer == null || !_sendTimer!.isActive) {
      _sendTimer = Timer(_sendInterval, () {
        _sendAllPwmSignals(); // Gọi hàm gửi thực tế
        _sendTimer = null; // Reset timer để cho phép gửi lần tiếp theo
      });
    }
  }

  // Hàm thực sự gửi dữ liệu, bao gồm kiểm tra thay đổi
  void _sendAllPwmSignals() {
    final currentCh1 = _ch3Value; // Đổi mapping: ch3 -> ch1
    final currentCh2 = _ch4Value; // ch4 -> ch2
    final currentCh3 = _ch1Value; // ch1 -> ch3
    final currentCh4 = _ch2Value; // ch2 -> ch4
    final currentCh5 = _angleValue;

    // Kiểm tra xem có bất kỳ giá trị nào đã thay đổi đáng kể không
    bool shouldSend =
        (currentCh1 - _lastSentCh1).abs() >= _pwmChangeThreshold ||
            (currentCh2 - _lastSentCh2).abs() >= _pwmChangeThreshold ||
            (currentCh3 - _lastSentCh3).abs() >= _pwmChangeThreshold ||
            (currentCh4 - _lastSentCh4).abs() >= _pwmChangeThreshold ||
            (currentCh5 - _lastSentCh5).abs() >= _angleChangeThreshold;

    if (shouldSend) {
      final dataToSend = {
        'ch1': currentCh1,
        'ch2': currentCh2,
        'ch3': currentCh3,
        'ch4': currentCh4,
        'ch5': currentCh5,
      };
      final jsonString = jsonEncode(dataToSend);

      emit(state.copyWith(lastSentData: jsonString));

      _communicationService.sendAllPwmValues(
        currentCh1,
        currentCh2,
        currentCh3,
        currentCh4,
        currentCh5,
      );

      // Cập nhật các giá trị đã gửi cuối cùng
      _lastSentCh1 = currentCh1;
      _lastSentCh2 = currentCh2;
      _lastSentCh3 = currentCh3;
      _lastSentCh4 = currentCh4;
      _lastSentCh5 = currentCh5;
    }
  }

  @override
  Future<void> connectToDevice() async {
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));
    try {
      await _communicationService.connect();
      emit(state.copyWith(connectionStatus: ConnectionStatus.connected));
      // Gửi trạng thái ban đầu sau khi kết nối thành công
      _sendAllPwmSignals();
    } catch (e) {
      emit(state.copyWith(connectionStatus: ConnectionStatus.error));
      print("CUBIT: Lỗi kết nối đến thiết bị: $e");
    }
  }

  @override
  Future<void> close() {
    _sendTimer?.cancel(); // Hủy timer khi đóng Cubit
    _communicationService.disconnect();
    _pwmDataSubscription?.cancel();
    return super.close();
  }
}