import 'package:flutter/material.dart';
import 'socket_service.dart';

class ConnectionScreen extends StatefulWidget {
  final SocketService socketService;
  final VoidCallback onConnected;

  const ConnectionScreen({
    super.key,
    required this.socketService,
    required this.onConnected,
  });

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _ipController = TextEditingController(text: '192.168.1.');
  final _portController = TextEditingController(text: '8765');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;

    if (ip.isEmpty) {
      setState(() => _errorMessage = 'Please enter an IP address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await widget.socketService.connect(ip, port);

    if (widget.socketService.isConnected) {
      widget.onConnected(); // navigate to controller screen
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect. Check IP and try again.';
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to PC')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.computer, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Enter your PC\'s local IP address',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // IP input
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PC IP Address',
                hintText: '192.168.1.x',
                prefixIcon: Icon(Icons.wifi),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Port input
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '8765',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Error message
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 24),

            // Connect button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _connect,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Connect', style: TextStyle(fontSize: 18)),
              ),
            ),

          ],
        ),
      ),
    );
  }
}