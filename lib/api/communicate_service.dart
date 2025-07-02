// lib/api/communicate_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart'; // Import thư viện WebSocket

class CommunicationService {
  final String _wsUrl;

  CommunicationService(this._wsUrl);

  // Hàm chuyển đổi góc (độ) sang micro giây cho servo
  int _angleToMicros(num angle) {
    return ((angle / 180) * 2000 + 500).round().clamp(500, 2500); // Dải servo thông thường là 500-2500 us
  }

  WebSocketChannel? _pwmChannel; // Kênh WebSocket cho dữ liệu PWM (/ws)
  WebSocketChannel? _toggleChannel; // Kênh WebSocket riêng cho dữ liệu Toggle (/toggle)

  StreamController<Map<String, dynamic>> _pwmDataStreamController = StreamController.broadcast();

  // Stream để các Widget hoặc Cubit khác có thể lắng nghe dữ liệu PWM từ ESP32
  Stream<Map<String, dynamic>> get pwmDataStream => _pwmDataStreamController.stream;

  // THÊM BIẾN NÀY ĐỂ LƯU TRỮ DỮ LIỆU PWM CUỐI CÙNG ĐƯỢC GỬI
  Map<String, dynamic>? _lastSentPwmData;
  // THÊM BIẾN NÀY ĐỂ LƯU TRỮ DỮ LIỆU TOGGLE CUỐI CÙNG ĐƯỢC GỬI
  Map<String, dynamic>? _lastSentToggleData;

  /// Kết nối tới các WebSocket server trên ESP32
  Future<void> connect() async {
    print("SERVICE: Đang kết nối WebSocket PWM tới $_wsUrl/ws");
    try {
      _pwmChannel = WebSocketChannel.connect(Uri.parse("ws://$_wsUrl/ws"));
      await _pwmChannel!.ready; // Chờ kết nối thiết lập

      _pwmChannel!.stream.listen(
            (message) {
          // Lắng nghe dữ liệu phản hồi từ ESP32 (ví dụ: xác nhận "ok")
          try {
            final Map<String, dynamic> response = jsonDecode(message);
            print("SERVICE: Nhận phản hồi từ ESP32: $response");
            // Nếu ESP32 gửi lại dữ liệu PWM, bạn có thể đẩy nó vào stream
            if (response.containsKey('ch1')) {
              _pwmDataStreamController.add(response);
            }
          } catch (e) {
            print("SERVICE: Lỗi phân tích JSON từ phản hồi WebSocket: $e, Message: $message");
          }
        },
        onError: (error) {
          print("SERVICE: Lỗi WebSocket PWM: $error");
          _pwmChannel?.sink.close(); // Đóng kết nối khi có lỗi
        },
        onDone: () {
          print("SERVICE: Kết nối WebSocket PWM đóng.");
        },
      );
      print("SERVICE: Kết nối WebSocket PWM thành công!");
    } catch (e) {
      print("SERVICE: Không thể kết nối WebSocket PWM: $e");
      rethrow; // Ném lại lỗi để Cubit có thể bắt và xử lý
    }

    // KẾT NỐI KÊNH TOGGLE RIÊNG
    print("SERVICE: Đang kết nối WebSocket TOGGLE tới $_wsUrl/toggle");
    try {
      _toggleChannel = WebSocketChannel.connect(Uri.parse("ws://$_wsUrl/toggle"));
      await _toggleChannel!.ready;
      // Không cần lắng nghe stream cho toggle nếu nó chỉ gửi đi
      print("SERVICE: Kết nối WebSocket TOGGLE thành công!");
    } catch (e) {
      print("SERVICE: Không thể kết nối WebSocket TOGGLE: $e");
      // Bạn có thể xử lý lỗi riêng cho kênh toggle nếu cần
    }
  }

  /// Phương thức mới để gửi tất cả 4 giá trị PWM cùng lúc
  void sendAllPwmValues(int ch1, int ch2, int ch3, int ch4, num angle) {
    // Kiểm tra xem kênh PWM có đang kết nối không
    if (_pwmChannel == null || _pwmChannel!.closeCode != null) {
      print("SERVICE: WebSocket PWM chưa kết nối. Không thể gửi dữ liệu PWM.");
      return;
    }

    final currentCh5 = _angleToMicros(angle); // Chuyển đổi góc sang micro giây

    final Map<String, dynamic> dataToSend = {
      'ch1': ch1,
      'ch2': ch2,
      'ch3': ch3,
      'ch4': ch4,
      'ch5': currentCh5,
    };

    // KIỂM TRA TRÙNG LẶP DỮ LIỆU TRƯỚC KHI GỬI
    if (_lastSentPwmData != null && _areMapsEqual(_lastSentPwmData!, dataToSend)) {
      // print("SERVICE: Dữ liệu PWM trùng lặp, bỏ qua gửi.");
      return;
    }

    _lastSentPwmData = dataToSend; // Cập nhật dữ liệu cuối cùng đã gửi
    _sendDataViaWebSocket(_pwmChannel!, dataToSend, "/ws"); // Sử dụng kênh PWM
  }

  // Phương thức mới để gửi dữ liệu công tắc qua kênh riêng /toggle
  void sendToggleData({required bool t1, required bool t2, required bool t3}) {
    // Kiểm tra xem kênh toggle có đang kết nối không
    if (_toggleChannel == null || _toggleChannel!.closeCode != null) {
      print("SERVICE: WebSocket TOGGLE chưa kết nối. Không thể gửi dữ liệu công tắc.");
      return;
    }

    final Map<String, dynamic> toggleData = {
      't1': t1, // Gửi trực tiếp giá trị boolean (true/false)
      't2': t2, // Gửi trực tiếp giá trị boolean (true/false)
      't3': t3, // Gửi trực tiếp giá trị boolean (true/false)
    };

    // KIỂM TRA TRÙNG LẶP DỮ LIỆU TRƯỚC KHI GỬI
    if (_lastSentToggleData != null && _areMapsEqual(_lastSentToggleData!, toggleData)) {
      // print("SERVICE: Dữ liệu Toggle trùng lặp, bỏ qua gửi.");
      return;
    }

    _lastSentToggleData = toggleData; // Cập nhật dữ liệu cuối cùng đã gửi
    // Gửi qua kênh _toggleChannel riêng biệt
    _sendDataViaWebSocket(_toggleChannel!, toggleData, "/toggle");
  }

  /// Hàm helper gửi dữ liệu JSON qua WebSocket tới một kênh cụ thể
  void _sendDataViaWebSocket(WebSocketChannel channel, Map<String, dynamic> data, String endpoint) {
    final jsonString = jsonEncode(data);
    print("SERVICE: Gửi qua WebSocket $endpoint: $jsonString");
    channel.sink.add(jsonString);
  }

  /// Hàm tiện ích để so sánh hai Map
  bool _areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) {
      return false;
    }
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  /// Đóng tất cả các kết nối WebSocket
  void disconnect() {
    if (_pwmChannel != null) {
      _pwmChannel!.sink.close();
      _pwmChannel = null;
      print("SERVICE: Đã ngắt kết nối WebSocket PWM.");
    }
    if (_toggleChannel != null) {
      _toggleChannel!.sink.close();
      _toggleChannel = null;
      print("SERVICE: Đã ngắt kết nối WebSocket TOGGLE.");
    }
    _pwmDataStreamController.close(); // Đóng stream controller
  }

  // ----- CÁC HÀM KHÔNG CÒN ĐƯỢC SỬ DỤNG HOẶC ĐÃ ĐƯỢC CHUYỂN LOGIC -----
  void sendJoystickData(String side, double x, double y) {
    print("SERVICE: sendJoystickData không còn được sử dụng trực tiếp. Logic đã chuyển sang Cubit.");
  }

  void sendSwitchData(int switchIndex, bool value) {
    print("SERVICE: sendSwitchData không còn được sử dụng trực tiếp. Logic đã chuyển sang Cubit.");
  }

  Future<void> getPwmValues() async {
    print("SERVICE: Lấy giá trị PWM sẽ thông qua WebSocket Stream lắng nghe phản hồi từ ESP32.");
  }
}