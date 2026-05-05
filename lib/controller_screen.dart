import 'package:flutter/material.dart';
import 'gyroscope_service.dart';
import 'socket_service.dart';

class ControllerScreen extends StatefulWidget {
  final GyroscopeService gyroService;
  final SocketService socketService;

  const ControllerScreen({
    super.key,
    required this.gyroService,
    required this.socketService,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    widget.gyroService.start(); // start listening to gyroscope
  }

  @override
  void dispose() {
    widget.gyroService.stop();
    super.dispose();
  }

  void _sendAction(String action) {
    widget.socketService.sendAction(action);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gyro Mouse'),
        actions: [
          // Disconnect button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.gyroService.stop();
              widget.socketService.disconnect();
            },
          )
        ],
      ),
      body: Column(
        children: [

          const SizedBox(height: 16),

          // Connection status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 12),
              const SizedBox(width: 6),
              const Text('Connected to PC'),
            ],
          ),

          const SizedBox(height: 16),

          // Sensitivity slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('Sensitivity'),
                Expanded(
                  child: Slider(
                    min: 1.0,
                    max: 20.0,
                    value: widget.gyroService.sensitivity,
                    onChanged: (val) {
                      setState(() {
                        widget.gyroService.updateSensitivity(val);
                      });
                    },
                  ),
                ),
                Text(widget.gyroService.sensitivity.toStringAsFixed(1)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Trackpad area — hold to move
          Expanded( 
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Listener(
                onPointerDown: (_) {
    widget.gyroService.setActive(true);
    setState(() => _isTracking = true);
  },
  onPointerUp: (_) {
    widget.gyroService.setActive(false);
    setState(() => _isTracking = false);
  },
  onPointerCancel: (_) {
    widget.gyroService.setActive(false);
    setState(() => _isTracking = false);
  },
                child: Container(
                  decoration: BoxDecoration(
                    color: _isTracking
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isTracking ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isTracking ? '🖱️ Moving...' : 'Hold to Move',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Click buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Left click
                Expanded(
                  child: GestureDetector(
                    onTap: () => _sendAction('left_click'),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Left Click',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Right click
                Expanded(
                  child: GestureDetector(
                    onTap: () => _sendAction('right_click'),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Right Click',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scroll buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Scroll up
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.socketService
                        .sendAction('scroll_up', amount: 3),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('▲ Scroll Up')),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Scroll down
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.socketService
                        .sendAction('scroll_down', amount: 3),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('▼ Scroll Down')),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}