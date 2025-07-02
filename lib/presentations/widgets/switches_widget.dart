// lib/presentations/widgets/switches_widget.dart
import 'package:flutter/material.dart';

class SwitchesWidget extends StatelessWidget {
  final Map<int, bool> switchValues; // ĐÃ THAY ĐỔI TỪ List<bool> SANG Map<int, bool>
  final Function(int index, bool value) onSwitchChanged;

  const SwitchesWidget({
    super.key,
    required this.switchValues,
    required this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // Đảm bảo rằng toàn bộ cột các công tắc được căn chỉnh đều
      crossAxisAlignment: CrossAxisAlignment.start, // Căn chỉnh các hàng con sang trái

      children: [
        // Hàng cho Arm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy text và switch ra hai bên
          children: [
            const Text("Arm", style: TextStyle(color: Colors.white, fontSize: 12)),
            Switch(
              // Sử dụng toán tử null-aware (??) để cung cấp giá trị mặc định nếu key không tồn tại
              value: switchValues[0] ?? false,
              onChanged: (val) => onSwitchChanged(0, val),
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        // Hàng cho Mode
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Mode", style: TextStyle(color: Colors.white, fontSize: 12)),
            Switch(
              value: switchValues[1] ?? false,
              onChanged: (val) => onSwitchChanged(1, val),
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        // Hàng cho Aux 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Aux 1", style: TextStyle(color: Colors.white, fontSize: 12)),
            Switch(
              value: switchValues[2] ?? false,
              onChanged: (val) => onSwitchChanged(2, val),
              activeColor: Colors.purple,
              inactiveThumbColor: Colors.grey,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }
}