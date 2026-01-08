import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class KilnService {
  static const String _wsUrl = 'ws://192.168.177.91:8000/ws';
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _controller.stream;

  void connect() {
    try {
      print('Connecting to WebSocket: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = json.decode(data);
            if (decoded is Map<String, dynamic>) {
              _controller.add(decoded);
            }
          } catch (e) {
            print('Error parsing WebSocket data: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _reconnect();
        },
      );
    } catch (e) {
      print('Connection error: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      print('Attempting to reconnect...');
      connect();
    });
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}
