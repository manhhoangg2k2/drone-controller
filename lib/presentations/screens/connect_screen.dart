import 'package:flutter/material.dart';

import 'fly_control_screen.dart';

class ConnectScreen extends StatefulWidget {
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _wsController = TextEditingController();
  final _camController = TextEditingController();

  // Khởi tạo giá trị mặc định cho URL và IP để tiện debug
  @override
  void initState() {
    super.initState();
    _wsController.text = '192.168.1.1';
    _camController.text = '192.168.1.1';
  }

  @override
  void dispose() {
    _wsController.dispose();
    _camController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Nền tối đồng bộ với FlyControlScreen
      body: Center(
        child: SingleChildScrollView( // Sử dụng SingleChildScrollView để tránh tràn màn hình khi bàn phím hiện lên
          padding: const EdgeInsets.all(32.0), // Tăng padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/Icon của ứng dụng
              Image.asset('assets/images/logo.png', height: 100,),
              const SizedBox(height: 20),
              Text(
                "Kết Nối Điều Khiển Bay",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // Trường nhập WebSocket URL
              _buildTextField(
                controller: _wsController,
                labelText: "WebSocket URL",
                hintText: "Ví dụ: ws://192.168.1.1:81",
                icon: Icons.wifi,
              ),
              const SizedBox(height: 20), // Tăng khoảng cách

              // Trường nhập Camera IP
              _buildTextField(
                controller: _camController,
                labelText: "Camera IP (MJPEG)",
                hintText: "Ví dụ: 192.168.1.1",
                icon: Icons.camera_alt,
              ),
              const SizedBox(height: 40), // Tăng khoảng cách

              // Nút kết nối
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlyControlScreen(
                        wsUrl: _wsController.text,
                        camIp: _camController.text,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue, // Màu nền nút
                  foregroundColor: Colors.white, // Màu chữ nút
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Bo tròn góc nút
                  ),
                  elevation: 5, // Đổ bóng cho nút
                ),
                child: const Text(
                  "KẾT NỐI",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng TextField tùy chỉnh để tránh lặp code
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white70, fontSize: 16), // Màu chữ nhập vào
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white38), // Màu chữ gợi ý
        labelStyle: TextStyle(color: Colors.white, fontSize: 16), // Màu chữ label
        prefixIcon: icon != null ? Icon(icon, color: Colors.lightBlueAccent) : null, // Icon đầu dòng
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey, width: 1.5), // Viền khi không focus
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.5), // Viền khi focus
          borderRadius: BorderRadius.circular(12),
        ),
        fillColor: Colors.black.withOpacity(0.3), // Màu nền của TextField
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}