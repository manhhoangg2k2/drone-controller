// lib/cubit/fly_control_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../api/communicate_service.dart';
import 'fly_control_state.dart';

class FlyControlCubit extends Cubit<FlyControlState> {
  final CommunicationService _communicationService;
  Timer? _sendTimer;
  final Duration _sendInterval = const Duration(milliseconds: 50);
  final String _wsUrl;

  // Biến để theo dõi xem đã có thay đổi joystick/slider lần đầu tiên chưa
  bool _hasInitialPwmSent = false;
  // Biến để theo dõi xem đã có thay đổi switch lần đầu tiên chưa
  bool _hasInitialToggleSent = false;


  FlyControlCubit(this._communicationService, this._wsUrl) : super(const FlyControlState());

  Future<void> connectToDevice() async {
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));
    try {
      await _communicationService.connect();
      emit(state.copyWith(
        connectionStatus: ConnectionStatus.connected,
        isWsConnected: true,
      ));
      // Khi kết nối thành công, đặt ch3 về 1000 và gửi ngay lập tức.
      // Reset cờ để đảm bảo lần thay đổi tiếp theo sẽ gửi dữ liệu.
      _hasInitialPwmSent = false;
      _hasInitialToggleSent = false;
      _sendInitialPwmState(); // Gửi trạng thái PWM ban đầu (ch3=1000)
    } catch (e) {
      emit(state.copyWith(
        connectionStatus: ConnectionStatus.error,
        lastSentData: "Lỗi kết nối: $e",
        isWsConnected: false,
      ));
    }
  }

  // Hàm gửi trạng thái PWM ban đầu: ch3 = 1000, các kênh khác mặc định
  void _sendInitialPwmState() {
    _communicationService.sendAllPwmValues(
      state.currentCh1, // Mặc định 1500
      state.currentCh2, // Mặc định 1500
      1000, // Đặt ch3 về 1000
      state.currentCh4, // Mặc định 1500
      state.currentCh5Angle, // Mặc định 90
      state.currentCh6Angle, // Mặc định 90
    );
    emit(state.copyWith(
      currentCh3: 1000, // Cập nhật trạng thái cubit
      lastSentData: "Initial: ch1:${state.currentCh1}, ch2:${state.currentCh2}, ch3:1000, ch4:${state.currentCh4}, ch5_angle:${state.currentCh5Angle}, ch6_angle:${state.currentCh6Angle}",
    ));
  }

  Future<void> toggleWsConnection(bool enable) async {
    if (enable) {
      await connectToDevice();
    } else {
      if (state.connectionStatus == ConnectionStatus.connected) {
        // Trước khi ngắt kết nối, gửi ch3 = 1000
        await _communicationService.sendAllPwmValues(
          state.currentCh1,
          state.currentCh2,
          1000, // Đặt ch3 về 1000
          state.currentCh4,
          state.currentCh5Angle,
          state.currentCh6Angle,
        );
        emit(state.copyWith(
          currentCh3: 1000, // Cập nhật trạng thái cục bộ
          lastSentData: "ch1:${state.currentCh1}, ch2:${state.currentCh2}, ch3:1000, ch4:${state.currentCh4}, ch5_angle:${state.currentCh5Angle}, ch6_angle:${state.currentCh6Angle}",
        ));
        // Đợi một chút để đảm bảo gói tin được gửi đi
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _communicationService.disconnect();
      emit(state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        isWsConnected: false,
      ));
    }
  }

  void updateLeftJoystick(double x, double y) {
    const double sensitivity = 500;

    double rotatedX = y;
    double rotatedY = x;

    int newCh1 = (1500 + (rotatedY * sensitivity)).round().clamp(1000, 2000); // Throttle (CH1) dùng y đã xoay
    int newCh2 = (1500 + (rotatedX * sensitivity)).round().clamp(1000, 2000);  // Yaw (CH2) dùng x đã xoay
    print("ch1: ${newCh1}, ch2: ${newCh2}");
    if (newCh1 != state.currentCh1 || newCh2 != state.currentCh2 || !_hasInitialPwmSent) {
      emit(state.copyWith(
        leftStickX: x,
        leftStickY: y,
        currentCh1: newCh1,
        currentCh2: newCh2,
      ));
      _scheduleSendAllCurrentPwmValues();
      _hasInitialPwmSent = true;
    }
  }

  void updateRightJoystick(double x, double y) {
    const double sensitivity = 500;

    int newCh3 = (1500 + (-y * sensitivity)).round().clamp(1000, 2000);
    int newCh4 = (1500 + (-x * sensitivity)).round().clamp(1000, 2000);

    print("ch3: ${newCh3}, ch4: ${newCh4}");
    if (newCh3 != state.currentCh3 || newCh4 != state.currentCh4 || !_hasInitialPwmSent) {
      emit(state.copyWith(
        rightStickX: x,
        rightStickY: y,
        currentCh3: newCh3,
        currentCh4: newCh4,
      ));
      _scheduleSendAllCurrentPwmValues();
      _hasInitialPwmSent = true;
    }
  }

  void updateAngleSlider(num angle) {
    // Lưu ý: sliderValue là 0.0-1.0, currentCh5Angle là 0-180
    if (angle != state.currentCh5Angle || !_hasInitialPwmSent) {
      emit(state.copyWith(
        sliderValue: angle / 180.0,
        currentCh5Angle: angle,
      ));
      _scheduleSendAllCurrentPwmValues();
      _hasInitialPwmSent = true;
    }
  }

  void updateAngle6Slider(num angle) {
    // Lưu ý: sliderValue là 0.0-1.0, currentCh5Angle là 0-180
    if (angle != state.currentCh6Angle || !_hasInitialPwmSent) {
      emit(state.copyWith(
        sliderValue2: angle / 180.0,
        currentCh6Angle: angle,
      ));
      _scheduleSendAllCurrentPwmValues();
      _hasInitialPwmSent = true;
    }
  }

  void updateSwitch(int index, bool value) {
    final Map<int, bool> updatedSwitches = Map.from(state.switchValues);
    updatedSwitches[index] = value;

    // Kiểm tra xem có thay đổi so với giá trị hiện tại của state hay là lần gửi đầu tiên
    if (state.switchValues[index] != value || !_hasInitialToggleSent) {
      emit(state.copyWith(switchValues: updatedSwitches));
      _communicationService.sendToggleData(
        t1: updatedSwitches[0] ?? false,
        t2: updatedSwitches[1] ?? false,
        t3: updatedSwitches[2] ?? false,
        t4: updatedSwitches[3] ?? false,
      );
      _hasInitialToggleSent = true;
    }
  }

  // Hàm để gửi tất cả 5 giá trị PWM hiện tại ngay lập tức
  void _sendAllCurrentPwmValuesImmediate() {
    if (!state.isWsConnected) {
      emit(state.copyWith(
        lastSentData: "WS đã ngắt. Dữ liệu không được gửi.",
      ));
      return;
    }

    _communicationService.sendAllPwmValues(
      state.currentCh1,
      state.currentCh2,
      state.currentCh3,
      state.currentCh4,
      state.currentCh5Angle,
      state.currentCh6Angle,
    );
    emit(state.copyWith(
      lastSentData: "ch1:${state.currentCh1}, ch2:${state.currentCh2}, ch3:${state.currentCh3}, ch4:${state.currentCh4}, ch5_angle:${state.currentCh5Angle}, ch6_angle:${state.currentCh6Angle}",
    ));
  }

  // Hàm lên lịch gửi dữ liệu, debounce các cuộc gọi liên tiếp
  void _scheduleSendAllCurrentPwmValues() {
    _sendTimer?.cancel();
    _sendTimer = Timer(_sendInterval, () {
      _sendAllCurrentPwmValuesImmediate();
      _sendTimer = null;
    });
  }

  @override
  Future<void> close() {
    _sendTimer?.cancel();
    _communicationService.disconnect();
    return super.close();
  }
}