import 'package:flutter/material.dart';
import 'socket_service.dart';
import 'sensor_service.dart';
import 'connection_screen.dart';
import 'controller_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Magic Mice',
      debugShowCheckedModeBanner: false,
      home: RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late SocketService _socketService;
  late SensorService _sensorService;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();

    _socketService = SocketService(
      onStatusChange: (status) {
        // If server drops connection, go back to connection screen
        if (status == ConnectionStatus.disconnected ||
            status == ConnectionStatus.error) {
          setState(() => _isConnected = false);
          _sensorService.stop();
        }
      },
    );

    _sensorService = SensorService(
      onMove: (dx, dy) {
        // Send movement to PC
        _socketService.sendMove(dx, dy);
      },
    );
  }

  @override
  void dispose() {
    _sensorService.stop();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return ConnectionScreen(
        socketService: _socketService,
        onConnected: () => setState(() => _isConnected = true),
      );
    }

    return ControllerScreen(
      sensorService: _sensorService,
      socketService: _socketService,
    );
  }
}