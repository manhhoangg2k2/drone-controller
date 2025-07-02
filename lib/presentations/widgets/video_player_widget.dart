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
  // Biến này được giữ lại, mặc dù không được sử dụng trực tiếp trong UI hiện tại
  // nhưng có thể dùng để hiển thị trạng thái debug.
  String _statusMessage = '';

  // Biến này kiểm soát việc stream có đang hoạt động hay không.
  // Đặt là true trong initState để stream bắt đầu ngay khi widget được tạo.
  bool _isStreaming = true;

  @override
  void initState() {
    super.initState();
    _isStreaming = true;
    // Bạn có thể thêm logic kiểm tra kết nối ban đầu hoặc hiển thị placeholder ở đây nếu muốn
    // Ví dụ: _checkInitialStreamStatus();
  }

  @override
  void dispose() {
    // Đặt _isStreaming về false khi widget bị hủy để dừng stream một cách an toàn.
    _isStreaming = false;
    super.dispose();
  }

  // Phương thức để thay đổi độ phân giải của camera.
  // Đã thêm cổng :81 vào URL để khớp với cấu hình server Node.js hoặc ESP32.
  Future<void> _changeResolution(int val) async {
    final url = 'http://${widget.camIp}:81/control?var=framesize&val=$val';
    try {
      final res = await http.get(Uri.parse(url));
      setState(() {
        _statusMessage = res.statusCode == 200
            ? 'Đổi độ phân giải OK (val=$val)'
            : 'Đổi độ phân giải LỖI (${res.statusCode})';
      });
      print('Change Resolution Status: $_statusMessage'); // In ra console để debug
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi đổi độ phân giải: $e';
      });
      print('Change Resolution Error: $_statusMessage'); // In ra console để debug
    }
  }

  // Phương thức để chụp ảnh từ camera.
  // Đã thêm cổng :81 vào URL để khớp với cấu hình server Node.js hoặc ESP32.
  Future<void> _captureSnapshot() async {
    final url = 'http://${widget.camIp}:81/capture';
    try {
      final res = await http.get(Uri.parse(url));
      setState(() {
        _statusMessage = res.statusCode == 200
            ? 'Chụp ảnh OK (${res.bodyBytes.length} bytes)'
            : 'Chụp ảnh LỖI (${res.statusCode})';
      });
      print('Capture Snapshot Status: $_statusMessage'); // In ra console để debug
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi chụp ảnh: $e';
      });
      print('Capture Snapshot Error: $_statusMessage'); // In ra console để debug
    }
  }

  // Phương thức để lấy trạng thái cảm biến từ camera.
  // Đã thêm cổng :81 vào URL để khớp với cấu hình server Node.js hoặc ESP32.
  Future<void> _getSensorStatus() async {
    final url = 'http://${widget.camIp}:81/status';
    try {
      final res = await http.get(Uri.parse(url));
      setState(() {
        if (res.statusCode == 200) {
          _statusMessage = 'Trạng thái: ${res.body}';
        } else {
          _statusMessage = 'Lỗi lấy trạng thái: ${res.statusCode}';
        }
      });
      print('Get Sensor Status: $_statusMessage'); // In ra console để debug
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi lấy trạng thái: $e';
      });
      print('Get Sensor Status Error: $_statusMessage'); // In ra console để debug
    }
  }

  @override
  Widget build(BuildContext context) {
    // URL của luồng video MJPEG, đã có cổng :81.
    final streamUrl = 'http://${widget.camIp}:81/stream';

    return
      Mjpeg(
      stream: streamUrl,
      isLive: _isStreaming, // Điều khiển việc phát stream
      fit: BoxFit.cover, // Video sẽ phóng to để bao phủ toàn bộ không gian có sẵn
      // Các thuộc tính placeholder và errorBuilder không được hỗ trợ trong phiên bản 2.0.4 của flutter_mjpeg.
      // Nếu bạn muốn hiển thị một placeholder hoặc thông báo lỗi khi không có stream,
      // bạn sẽ cần bọc Mjpeg bằng các widget khác như Stack hoặc FutureBuilder để quản lý trạng thái tải/lỗi.
      // Ví dụ:
      // return FutureBuilder<void>(
      //   future: _checkStreamAvailability(streamUrl), // Một hàm kiểm tra kết nối stream
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Center(child: CircularProgressIndicator());
      //     } else if (snapshot.hasError) {
      //       return Center(child: Text('Lỗi tải stream: ${snapshot.error}'));
      //     } else {
      //       return Mjpeg(
      //         stream: streamUrl,
      //         isLive: _isStreaming,
      //         fit: BoxFit.cover,
      //       );
      //     }
      //   },
      // );
    );
  }

// Hàm ví dụ để kiểm tra tính khả dụng của stream (nếu bạn muốn thêm placeholder/error handling)
// Future<void> _checkStreamAvailability(String url) async {
//   try {
//     // Thay vì HTTP GET, thực tế bạn sẽ cần kiểm tra xem MJPEG stream có thực sự bắt đầu không.
//     // Việc này phức tạp hơn vì nó là một luồng liên tục.
//     // Thường thì chỉ cần dựa vào lỗi của Mjpeg widget (nếu có) hoặc thử tải một ảnh tĩnh trước.
//     // Đối với MJPEG, Mjpeg widget thường tự xử lý kết nối.
//     // Đây chỉ là một ví dụ placeholder, có thể không hoàn toàn chính xác cho stream MJPEG.
//     final response = await http.head(Uri.parse(url)).timeout(Duration(seconds: 5));
//     if (response.statusCode != 200) {
//       throw Exception('Stream not available: ${response.statusCode}');
//     }
//   } catch (e) {
//     throw Exception('Failed to connect to stream: $e');
//   }
// }
}