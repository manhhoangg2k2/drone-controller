// lib/cubit/fly_control_state.dart

import 'package:equatable/equatable.dart';

enum ConnectionStatus { initial, connecting, connected, disconnected, error }

class FlyControlState extends Equatable {
  final ConnectionStatus connectionStatus;
  final double leftStickX;
  final double leftStickY;
  final double rightStickX;
  final double rightStickY;
  final double sliderValue; // 0.0 - 1.0 (cho UI Slider)
  final Map<int, bool> switchValues; // ĐÃ THAY ĐỔI TỪ List<bool> SANG Map<int, bool>
  final String lastSentData;

  // CÁC TRƯỜNG ĐỂ LƯU TRỮ GIÁ TRỊ PWM HIỆN TẠI CỦA CÁC KÊNH
  final int currentCh1; // Throttle
  final int currentCh2; // Yaw
  final int currentCh3; // Pitch
  final int currentCh4; // Roll
  final num currentCh5Angle; // Góc servo (0-180)

  const FlyControlState({
    this.connectionStatus = ConnectionStatus.initial,
    this.leftStickX = 0.0,
    this.leftStickY = 0.0,
    this.rightStickX = 0.0,
    this.rightStickY = 0.0,
    this.sliderValue = 0.5, // Mặc định 90 độ cho servo (0.5 * 180)
    this.switchValues = const {0: false, 1: false, 2: false}, // Khởi tạo 3 công tắc
    this.lastSentData = "",
    // KHỞI TẠO GIÁ TRỊ MẶC ĐỊNH CHO CÁC KÊNH PWM
    this.currentCh1 = 1500,
    this.currentCh2 = 1500,
    this.currentCh3 = 1500,
    this.currentCh4 = 1500,
    this.currentCh5Angle = 90, // Mặc định 90 độ
  });

  FlyControlState copyWith({
    ConnectionStatus? connectionStatus,
    double? leftStickX,
    double? leftStickY,
    double? rightStickX,
    double? rightStickY,
    double? sliderValue,
    Map<int, bool>? switchValues, // ĐÃ THAY ĐỔI TỪ List<bool> SANG Map<int, bool>
    String? lastSentData,
    // Cập nhật các trường kênh PWM
    int? currentCh1,
    int? currentCh2,
    int? currentCh3,
    int? currentCh4,
    num? currentCh5Angle,
  }) {
    return FlyControlState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      leftStickX: leftStickX ?? this.leftStickX,
      leftStickY: leftStickY ?? this.leftStickY,
      rightStickX: rightStickX ?? this.rightStickX,
      rightStickY: rightStickY ?? this.rightStickY,
      sliderValue: sliderValue ?? this.sliderValue,
      switchValues: switchValues ?? this.switchValues,
      lastSentData: lastSentData ?? this.lastSentData,
      // Cập nhật các giá trị kênh
      currentCh1: currentCh1 ?? this.currentCh1,
      currentCh2: currentCh2 ?? this.currentCh2,
      currentCh3: currentCh3 ?? this.currentCh3,
      currentCh4: currentCh4 ?? this.currentCh4,
      currentCh5Angle: currentCh5Angle ?? this.currentCh5Angle,
    );
  }

  @override
  List<Object?> get props => [
    connectionStatus,
    leftStickX,
    leftStickY,
    rightStickX,
    rightStickY,
    sliderValue,
    switchValues,
    lastSentData,
    // Thêm các trường vào props
    currentCh1,
    currentCh2,
    currentCh3,
    currentCh4,
    currentCh5Angle,
  ];
}