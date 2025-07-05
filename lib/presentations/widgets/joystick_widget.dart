// lib/presentations/widgets/joystick_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class JoystickWidget extends StatelessWidget {
  final String side;
  final double x;
  final double y;
  final Function(StickDragDetails) onChanged;

  const JoystickWidget({
    super.key,
    required this.side,
    required this.x,
    required this.y,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Joystick(
          mode: JoystickMode.all,
          listener: onChanged,
          base: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
                border: Border.all(color: Colors.lightBlue, width: 2)),
          ),
          // Bạn có thể thêm lại stick nếu muốn một hình ảnh/icon cho tay cầm
          // stick: const Icon(Icons.gamepad, size: 80, color: Colors.lightBlueAccent), // Kích thước icon cũng sẽ lớn hơn
        ),
        const SizedBox(height: 8), // Khoảng cách giữa joystick và text
        Text(
          side,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          'X: ${x.toStringAsFixed(2)}, Y: ${y.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}