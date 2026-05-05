import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SocketService {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  // Callback so UI can react to status changes
  final void Function(ConnectionStatus status)? onStatusChange;

  SocketService({this.onStatusChange});

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  void _setStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    onStatusChange?.call(newStatus);
  }

  Future<void> connect(String ip, int port) async {
    if (_status == ConnectionStatus.connected) return;

    _setStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse('ws://$ip:$port');
      _channel = WebSocketChannel.connect(uri);

      // Wait to confirm connection
      await _channel!.ready;

      _setStatus(ConnectionStatus.connected);
      print('✅ Connected to $uri');

      // Listen for disconnection
      _channel!.stream.listen(
        (message) {
          // Server can send messages — handle if needed
          print('📩 Server: $message');
        },
        onDone: () {
          print('🔌 Disconnected from server');
          _setStatus(ConnectionStatus.disconnected);
        },
        onError: (error) {
          print('❌ Socket error: $error');
          _setStatus(ConnectionStatus.error);
        },
      );
    } catch (e) {
      print('❌ Connection failed: $e');
      _setStatus(ConnectionStatus.error);
    }
  }

  void sendMove(double dx, double dy) {
    if (!isConnected) return;

    final message = jsonEncode({'dx': dx, 'dy': dy});
    _send(message);
  }

  void sendAction(String action, {int? amount, String? key}) {
    if (!isConnected) return;

    final Map<String, dynamic> data = {'action': action};
    if (amount != null) data['amount'] = amount;
    if (key != null) data['key'] = key;

    _send(jsonEncode(data));
  }

  void _send(String message) {
    try {
      _channel?.sink.add(message);
    } catch (e) {
      print('❌ Send failed: $e');
      _setStatus(ConnectionStatus.error);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
    print('🔌 Manually disconnected');
  }
}