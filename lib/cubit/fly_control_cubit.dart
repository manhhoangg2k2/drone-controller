// lib/cubit/fly_control_cubit.dart

import 'dart:async'; // THÊM DÒNG NÀY ĐỂ SỬ DỤNG Timer

import 'package:flutter_bloc/flutter_bloc.dart';
import '../api/communicate_service.dart';
import 'fly_control_state.dart';

class FlyControlCubit extends Cubit<FlyControlState> {
  final CommunicationService _communicationService;
  Timer? _sendTimer; // Biến Timer để quản lý debounce
  // Đặt _sendInterval phù hợp với tần suất cập nhật mong muốn (ví dụ: 50ms = 20 lần/giây)
  final Duration _sendInterval = const Duration(milliseconds: 50);

  FlyControlCubit(this._communicationService) : super(const FlyControlState());

  Future<void> connectToDevice() async {
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));
    try {
      await _communicationService.connect();
      emit(state.copyWith(connectionStatus: ConnectionStatus.connected));
      _sendAllCurrentPwmValuesImmediate(); // Gửi ngay giá trị ban đầu khi kết nối thành công
    } catch (e) {
      emit(state.copyWith(
        connectionStatus: ConnectionStatus.error,
        lastSentData: "Lỗi kết nối: $e",
      ));
    }
  }

  void updateLeftJoystick(double x, double y) {
    const double sensitivity = 250;
    int newCh1 = (1500 + (y * sensitivity)).round().clamp(1000, 2000);
    int newCh2 = (1500 + (x * sensitivity)).round().clamp(1000, 2000);

    emit(state.copyWith(
      leftStickX: x,
      leftStickY: y,
      currentCh1: newCh1,
      currentCh2: newCh2,
    ));
    _scheduleSendAllCurrentPwmValues(); // THAY THẾ BẰNG HÀM SCHEDULE ĐỂ DEBOUNCE
  }

  void updateRightJoystick(double x, double y) {
    const double sensitivity = 250;
    int newCh3 = (1500 + (y * sensitivity)).round().clamp(1000, 2000);
    int newCh4 = (1500 + (x * sensitivity)).round().clamp(1000, 2000);

    emit(state.copyWith(
      rightStickX: x,
      rightStickY: y,
      currentCh3: newCh3,
      currentCh4: newCh4,
    ));
    _scheduleSendAllCurrentPwmValues(); // THAY THẾ BẰNG HÀM SCHEDULE ĐỂ DEBOUNCE
  }

  void updateAngleSlider(num angle) {
    emit(state.copyWith(
      sliderValue: angle / 180.0,
      currentCh5Angle: angle,
    ));
    _scheduleSendAllCurrentPwmValues(); // THAY THẾ BẰNG HÀM SCHEDULE ĐỂ DEBOUNCE
  }

  void updateSwitch(int index, bool value) {
    final Map<int, bool> updatedSwitches = Map.from(state.switchValues);
    updatedSwitches[index] = value;
    emit(state.copyWith(switchValues: updatedSwitches));
    // Đối với công tắc, thường không cần debounce vì các sự kiện là rời rạc
    _communicationService.sendToggleData(
      t1: updatedSwitches[0] ?? false,
      t2: updatedSwitches[1] ?? false,
      t3: updatedSwitches[2] ?? false,
    );
  }

  // Hàm để gửi tất cả 5 giá trị PWM hiện tại ngay lập tức
  void _sendAllCurrentPwmValuesImmediate() {
    _communicationService.sendAllPwmValues(
      state.currentCh1,
      state.currentCh2,
      state.currentCh3,
      state.currentCh4,
      state.currentCh5Angle,
    );
    // Cập nhật lastSentData để hiển thị trên UI, giúp debug
    emit(state.copyWith(
      lastSentData: "ch1:${state.currentCh1}, ch2:${state.currentCh2}, ch3:${state.currentCh3}, ch4:${state.currentCh4}, ch5_angle:${state.currentCh5Angle}",
    ));
  }

  // Hàm lên lịch gửi dữ liệu, debounce các cuộc gọi liên tiếp
  void _scheduleSendAllCurrentPwmValues() {
    // Hủy timer hiện có nếu nó đang chạy để bắt đầu lại đếm ngược
    _sendTimer?.cancel();
    // Lên lịch gửi dữ liệu sau một khoảng thời gian
    _sendTimer = Timer(_sendInterval, () {
      _sendAllCurrentPwmValuesImmediate(); // Gửi dữ liệu khi timer kết thúc
      _sendTimer = null; // Đặt lại timer sau khi gửi
    });
  }

  @override
  Future<void> close() {
    _sendTimer?.cancel(); // Hủy timer khi Cubit đóng để tránh rò rỉ bộ nhớ
    _communicationService.disconnect();
    return super.close();
  }
}