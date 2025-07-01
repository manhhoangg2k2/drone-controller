// lib/cubit/fly_control_state.dart
import 'package:equatable/equatable.dart';

enum ConnectionStatus { initial, connecting, connected, disconnected, error }

class FlyControlState extends Equatable {
  final double leftStickX;
  final double leftStickY;
  final double rightStickX;
  final double rightStickY;
  final List<bool> switchValues;
  final double sliderValue;
  final ConnectionStatus connectionStatus;
  final String lastSentData;

  const FlyControlState({
    this.leftStickX = 0.0,
    this.leftStickY = 0.0,
    this.rightStickX = 0.0,
    this.rightStickY = 0.0,
    this.switchValues = const [false, false, false], // THAY ĐỔI Ở ĐÂY: Thêm false cho công tắc thứ 3
    this.sliderValue = 0.0,
    this.connectionStatus = ConnectionStatus.initial,
    this.lastSentData = 'Chưa có dữ liệu',
  });

  FlyControlState copyWith({
    double? leftStickX,
    double? leftStickY,
    double? rightStickX,
    double? rightStickY,
    List<bool>? switchValues,
    double? sliderValue,
    ConnectionStatus? connectionStatus,
    String? lastSentData,
  }) {
    return FlyControlState(
      leftStickX: leftStickX ?? this.leftStickX,
      leftStickY: leftStickY ?? this.leftStickY,
      rightStickX: rightStickX ?? this.rightStickX,
      rightStickY: rightStickY ?? this.rightStickY,
      switchValues: switchValues ?? this.switchValues,
      sliderValue: sliderValue ?? this.sliderValue,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastSentData: lastSentData ?? this.lastSentData,
    );
  }

  @override
  List<Object?> get props => [
    leftStickX,
    leftStickY,
    rightStickX,
    rightStickY,
    switchValues,
    sliderValue,
    connectionStatus,
    lastSentData,
  ];
}