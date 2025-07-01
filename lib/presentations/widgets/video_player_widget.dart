import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;

class VideoPlayerWidget extends StatefulWidget {
  final String camIp;

  const VideoPlayerWidget({super.key, required this.camIp});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  String _statusMessage = '';
  bool _isStreaming = true;

  @override
  void initState() {
    super.initState();
    _isStreaming = true;
  }

  @override
  void dispose() {
    _isStreaming = false;
    super.dispose();
  }

  // Các phương thức điều khiển camera (giữ nguyên)
  Future<void> _changeResolution(int val) async {
    final url = 'http://${widget.camIp}/control?var=framesize&val=$val';
    try {
      final res = await http.get(Uri.parse(url));
      setState(() {
        _statusMessage = res.statusCode == 200
            ? 'Đổi độ phân giải OK (val=$val)'
            : 'Đổi độ phân giải LỖI (${res.statusCode})';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi đổi độ phân giải: $e';
      });
    }
  }

  Future<void> _captureSnapshot() async {
    final url = 'http://${widget.camIp}/capture';
    try {
      final res = await http.get(Uri.parse(url));
      setState(() {
        _statusMessage = res.statusCode == 200
            ? 'Chụp ảnh OK (${res.bodyBytes.length} bytes)'
            : 'Chụp ảnh LỖI (${res.statusCode})';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi chụp ảnh: $e';
      });
    }
  }

  Future<void> _getSensorStatus() async {
    final url = 'http://${widget.camIp}/status';
    try {
      final res = await http.get(Uri.parse(url));
      setState(() {
        if (res.statusCode == 200) {
          _statusMessage = 'Trạng thái: ${res.body}';
        } else {
          _statusMessage = 'Lỗi lấy trạng thái: ${res.statusCode}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi lấy trạng thái: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamUrl = 'http://${widget.camIp}:81/stream';
    return Mjpeg( // Trực tiếp trả về Mjpeg
      stream: streamUrl,
      isLive: _isStreaming,
      fit: BoxFit.cover, // <--- THAY ĐỔI QUAN TRỌNG NHẤT Ở ĐÂY
      // BoxFit.cover sẽ làm video phóng to để bao phủ toàn bộ không gian có sẵn của nó (màn hình).
      // Nếu tỉ lệ khung hình của video không khớp với màn hình, một phần của video sẽ bị cắt đi.
      // Điều này đảm bảo video luôn "bao hết" màn hình theo một chiều nào đó
      // và không bị bé nhỏ ở giữa.
      // placeholder và errorBuilder không được hỗ trợ trong phiên bản 2.0.4 của flutter_mjpeg
    );
  }
}