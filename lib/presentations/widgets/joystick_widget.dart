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
      mainAxisAlignment: MainAxisAlignment.end, // Căn joystick xuống dưới
      children: [
        // Text(side, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), // Có thể thêm lại để debug
        // const SizedBox(height: 10),
        Joystick(
          mode: JoystickMode.all, // Cho phép di chuyển theo mọi hướng
          listener: onChanged, // Gửi chi tiết di chuyển lên Cubit
          base: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
                border: Border.all(color: Colors.lightBlue, width: 2)),
          ),
          // stick: const Icon(Icons.gamepad, size: 60, color: Colors.lightBlueAccent), // Có thể thêm lại stick nếu muốn
        ),
        // Để debug, bạn có thể uncomment các dòng này để thấy giá trị X, Y
        // const SizedBox(height: 10),
        // Text("X: ${x.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
        // Text("Y: ${y.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}