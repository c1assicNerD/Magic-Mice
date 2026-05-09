import 'package:flutter/material.dart';
import 'sensor_service.dart';
import 'socket_service.dart';

class ControllerScreen extends StatefulWidget {
  final SensorService sensorService;
  final SocketService socketService;

  const ControllerScreen({
    super.key,
    required this.sensorService,
    required this.socketService,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  bool _isTracking = false;
  MovementMode _selectedMode = MovementMode.combined;

  @override
  void initState() {
    super.initState();
    widget.sensorService.start();
  }

  @override
  void dispose() {
    widget.sensorService.stop();
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
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.sensorService.stop();
              widget.socketService.disconnect();
            },
          )
        ],
      ),
      body: Column(
        children: [

          const SizedBox(height: 12),

          // ── Mode selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<MovementMode>(
                  segments: const [
                    ButtonSegment(
                      value: MovementMode.gyroscope,
                      label: Text('Tilt'),
                      icon: Icon(Icons.screen_rotation),
                    ),
                    ButtonSegment(
                      value: MovementMode.combined,
                      label: Text('Both'),
                      icon: Icon(Icons.merge),
                    ),
                    ButtonSegment(
                      value: MovementMode.linear,
                      label: Text('Move'),
                      icon: Icon(Icons.open_with),
                    ),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedMode = value.first;
                      widget.sensorService.updateMode(_selectedMode);
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height:8),

          // ── Blend slider (only visible in combined mode) ──
          if (_selectedMode == MovementMode.combined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text('Tilt', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      min: 0.0,
                      max: 1.0,
                      value: widget.sensorService.blendWeight,
                      onChanged: (val) {
                        setState(() {
                          widget.sensorService.updateBlend(val);
                        });
                      },
                    ),
                  ),
                  const Text('Move', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

          // ── Sensitivity slider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('Sensitivity'),
                Expanded(
                  child: Slider(
                    min: 1.0,
                    max: 20.0,
                    value: widget.sensorService.sensitivity,
                    onChanged: (val) {
                      setState(() {
                        widget.sensorService.updateSensitivity(val);
                      });
                    },
                  ),
                ),
                Text(widget.sensorService.sensitivity.toStringAsFixed(1)),
              ],
            ),
          ),

          // ── Trackpad hold area ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Listener(
                onPointerDown: (_) {
                  widget.sensorService.setActive(true);
                  setState(() => _isTracking = true);
                },
                onPointerUp: (_) {
                  widget.sensorService.setActive(false);
                  setState(() => _isTracking = false);
                },
                onPointerCancel: (_) {
                  widget.sensorService.setActive(false);
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isTracking ? '🖱️ Moving...' : 'Hold to Move',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedMode == MovementMode.gyroscope
                              ? 'Tilt to move cursor'
                              : _selectedMode == MovementMode.linear
                                  ? 'Move phone to move cursor'
                                  : 'Tilt + Move combined',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Click buttons ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
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
                        child: Text('Left Click',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        child: Text('Right Click',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Scroll buttons ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        widget.socketService.sendAction('scroll_up', amount: 3),
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