// lib/presentations/screens/fly_control_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/fly_control_cubit.dart';
import '../../cubit/fly_control_state.dart';
import '../../api/communicate_service.dart';
import '../widgets/joystick_widget.dart';
import '../widgets/switches_widget.dart';
import '../widgets/video_player_widget.dart';
import 'connect_screen.dart'; // Đảm bảo dòng này đã có nếu bạn muốn nút quay lại màn hình kết nối

class FlyControlScreen extends StatelessWidget {
  final String wsUrl;
  final String camIp;

  const FlyControlScreen({
    super.key,
    required this.wsUrl,
    required this.camIp,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FlyControlCubit(CommunicationService(wsUrl), wsUrl)..connectToDevice(), // Truyền wsUrl vào Cubit
      child: _FlyControlScreenBody(camIp: camIp),
    );
  }
}

class _FlyControlScreenBody extends StatelessWidget {
  final String camIp;

  const _FlyControlScreenBody({super.key, required this.camIp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Nền tối hơn
      body: BlocBuilder<FlyControlCubit, FlyControlState>(
        builder: (context, state) {
          return SafeArea( // Sử dụng SafeArea để tránh các notch và thanh trạng thái
            child: Stack(
              children: [
                // Video Player (Toàn màn hình)
                Positioned.fill(
                  child: VideoPlayerWidget(camIp: camIp),
                ),

                // Lớp phủ mờ để các widget dễ nhìn hơn
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // Tăng độ mờ
                  ),
                ),

                // Angle Slider ở góc trên bên trái
                Positioned(
                  top: 16,
                  left: 16,
                  child: _AngleSlider(),
                ),

                // KHỐI ĐIỀU KHIỂN BÊN PHẢI (TRẠNG THÁI, CÔNG TẮC, CÀI ĐẶT)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Căn chỉnh sang phải
                    children: [
                      _SettingsButton(), // Nút cài đặt
                      const SizedBox(width: 10),

                      _WsToggleButton(), // Nút bật/tắt WS connection
                      const SizedBox(width: 10),

                      _StatusAndControls(), // Chứa trạng thái và các công tắc
                    ],
                  ),
                ),


                // BOTTOM ROW: Joysticks
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Joystick trái
                      JoystickWidget(
                        side: 'Trái (Pitch/Roll)', // Cập nhật nhãn
                        x: state.leftStickX, // Vẫn hiển thị giá trị x, y thô cho debug
                        y: state.leftStickY,
                        onChanged: (details) {
                          context.read<FlyControlCubit>().updateLeftJoystick(details.x, details.y);
                        },
                      ),
                      // Joystick phải
                      JoystickWidget(
                        side: 'Phải (Throttle/Yaw)', // Cập nhật nhãn
                        x: state.rightStickX, // Vẫn hiển thị giá trị x, y thô cho debug
                        y: state.rightStickY,
                        onChanged: (details) {
                          context.read<FlyControlCubit>().updateRightJoystick(details.x, details.y);
                        },
                      ),
                    ],
                  ),
                ),

                // Hiển thị dữ liệu gửi đi ở trung tâm dưới (có thể điều chỉnh vị trí)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        "Gửi: ${state.lastSentData}",
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusAndControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlyControlCubit, FlyControlState>(
      builder: (context, state) {
        Color color;
        String text;
        IconData icon;

        switch (state.connectionStatus) {
          case ConnectionStatus.connected:
            color = Colors.greenAccent; // Màu sáng hơn
            text = "Kết nối";
            icon = Icons.check_circle;
            break;
          case ConnectionStatus.connecting:
            color = Colors.yellowAccent;
            text = "Đang kết nối";
            icon = Icons.hourglass_top;
            break;
          case ConnectionStatus.error:
          case ConnectionStatus.disconnected:
            color = Colors.redAccent;
            text = "Mất kết nối";
            icon = Icons.error;
            break;
          default:
            color = Colors.grey;
            text = "Chưa kết nối";
            icon = Icons.help;
        }

        return Container(
          padding: const EdgeInsets.all(8), // Giảm padding để nhỏ gọn hơn
          decoration: BoxDecoration(
            color: const Color(0xFF2D2A4F).withOpacity(0.8), // Màu nền đậm hơn
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.lightBlue.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Giới hạn kích thước theo nội dung
            crossAxisAlignment: CrossAxisAlignment.end, // Căn chỉnh các phần tử sang phải
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Căn chỉnh status sang phải
                children: [
                  Icon(icon, color: color, size: 16), // Giảm kích thước icon
                  const SizedBox(width: 6), // Giảm khoảng cách
                  Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)), // Giảm kích thước chữ
                ],
              ),
              const SizedBox(height: 8), // Giảm khoảng cách
              // Sử dụng IntrinsicWidth để SwichesWidget chỉ chiếm không gian cần thiết
              IntrinsicWidth(
                child: SwitchesWidget(
                  switchValues: state.switchValues,
                  onSwitchChanged: (index, value) {
                    context.read<FlyControlCubit>().updateSwitch(index, value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AngleSlider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlyControlCubit, FlyControlState>(
      builder: (context, state) {
        final angle = (state.sliderValue * 180).round();
        return Container(
          width: 180, // Giới hạn chiều rộng cho Slider
          padding: const EdgeInsets.all(8), // Giảm padding
          decoration: BoxDecoration(
            color: const Color(0xFF2D2A4F).withOpacity(0.8), // Màu nền đậm hơn
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.lightBlue.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Căn chỉnh tiêu đề sang trái
            children: [
              const Text(
                "Điều khiển camera",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), // Giảm kích thước chữ
              ),
              const SizedBox(height: 6), // Giảm khoảng cách
              Text(
                "Góc: $angle°",
                style: const TextStyle(color: Colors.white70, fontSize: 10), // Giảm kích thước chữ
              ),
              Slider(
                value: state.sliderValue,
                min: 0,
                max: 1,
                divisions: 18, // Chia 180 độ thành 18 phần, mỗi phần 10 độ
                label: "$angle°",
                onChanged: (val) {
                  context.read<FlyControlCubit>().updateAngleSlider(val * 180);
                },
                activeColor: Colors.orangeAccent, // Màu cam sáng hơn
                inactiveColor: Colors.orangeAccent.withOpacity(0.3),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget mới cho nút bật/tắt kết nối WebSocket
class _WsToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlyControlCubit, FlyControlState>(
      builder: (context, state) {
        final bool isConnected = state.isWsConnected;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2A4F).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.lightBlue.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                context.read<FlyControlCubit>().toggleWsConnection(!isConnected);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.link_off : Icons.link,
                      color: isConnected ? Colors.redAccent : Colors.greenAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? "Ngắt WS" : "Kết nối WS",
                      style: TextStyle(
                        color: isConnected ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// Widget mới cho nút cài đặt
class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2A4F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Khi nhấn nút, điều hướng về màn hình ConnectScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ConnectScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Giảm padding
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 18), // Giảm kích thước icon
                SizedBox(width: 6), // Giảm khoảng cách
                Text(
                  "Cài đặt lại IP",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), // Giảm kích thước chữ
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}