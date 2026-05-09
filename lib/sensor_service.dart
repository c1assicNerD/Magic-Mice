import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

enum MovementMode { gyroscope, linear, combined }

class SensorService {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;

  double sensitivity = 5.0;

  final double _gyroDeadZone = 0.03;
  final double _accelDeadZone = 0.3; // much higher — accel is very noisy

  final Duration _minInterval = const Duration(milliseconds: 16);

  final double _gyroAlpha = 0.2;
  final double _accelAlpha = 0.1; // very smooth to reduce noise

  double _smoothGyroX = 0;
  double _smoothGyroY = 0;
  double _smoothAccelX = 0;
  double _smoothAccelY = 0;

  double _gyroContribX = 0;
  double _gyroContribY = 0;
  double _accelContribX = 0;
  double _accelContribY = 0;

  bool _active = false;
  DateTime? _lastSent;
  DateTime? _lastGyroEvent;
  DateTime? _lastAccelEvent;

  // Blend: 0.0 = full gyro, 1.0 = full linear
  double blendWeight = 0.0; // start with gyro only by default

  MovementMode mode = MovementMode.gyroscope; // default to gyro only

  final void Function(double dx, double dy) onMove;

  SensorService({required this.onMove});

  void start() {
    _startGyroscope();
    _startAccelerometer();
  }

  void _startGyroscope() {
    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onGyroEvent);
  }

  void _startAccelerometer() {
    _accelSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onAccelEvent);
  }

  void _onGyroEvent(GyroscopeEvent event) {
    if (!_active) return;

    final now = DateTime.now();
    double dt = 0.02;
    if (_lastGyroEvent != null) {
      dt = now.difference(_lastGyroEvent!).inMicroseconds / 1000000.0;
      dt = dt.clamp(0.001, 0.1);
    }
    _lastGyroEvent = now;

    double rawX = event.y;
    double rawY = event.x;

    double magnitude = rawX * rawX + rawY * rawY;
    if (magnitude < _gyroDeadZone) {
      // Decay toward zero — smooth stop
      _smoothGyroX *= 0.85;
      _smoothGyroY *= 0.85;
    } else {
      _smoothGyroX = (_gyroAlpha * rawX) + ((1 - _gyroAlpha) * _smoothGyroX);
      _smoothGyroY = (_gyroAlpha * rawY) + ((1 - _gyroAlpha) * _smoothGyroY);
    }

    _gyroContribX = _smoothGyroX * sensitivity * dt * 100;
    _gyroContribY = _smoothGyroY * sensitivity * dt * 100;

    _trySend(now);
  }

  void _onAccelEvent(UserAccelerometerEvent event) {
    if (!_active) return;

    final now = DateTime.now();
    double dt = 0.02;
    if (_lastAccelEvent != null) {
      dt = now.difference(_lastAccelEvent!).inMicroseconds / 1000000.0;
      dt = dt.clamp(0.001, 0.1);
    }
    _lastAccelEvent = now;

    // Only use X axis for horizontal movement — most natural feeling
    // Ignore Y axis (forward/back) — causes rubber band effect
    double rawX = event.x;

    // Apply high dead zone — stops drift when phone is still
    if (rawX.abs() < _accelDeadZone) {
      _smoothAccelX *= 0.5; // fast decay
      _accelContribX = 0;
      _accelContribY = 0;
      return;
    }

    _smoothAccelX = (_accelAlpha * rawX) + ((1 - _accelAlpha) * _smoothAccelX);

    // Only horizontal linear movement — no Y to avoid rubber band
    _accelContribX = _smoothAccelX * sensitivity * dt * 80;
    _accelContribY = 0; // intentionally zero

    _trySend(now);
  }

  void _trySend(DateTime now) {
    if (_lastSent != null &&
        now.difference(_lastSent!) < _minInterval) return;

    double dx = 0;
    double dy = 0;

    switch (mode) {
      case MovementMode.gyroscope:
        // Pure gyro — most stable
        dx = _gyroContribX;
        dy = _gyroContribY;
        break;

      case MovementMode.linear:
        // Pure linear — horizontal movement only
        dx = _accelContribX;
        dy = 0;
        break;

      case MovementMode.combined:
        // Gyro handles Y (up/down) always
        // Blend handles X (left/right) between tilt and move
        dx = (_gyroContribX * (1 - blendWeight)) +
             (_accelContribX * blendWeight);
        dy = _gyroContribY; // Y always from gyro — accel Y is unreliable
        break;
    }

    if (dx.abs() < 0.01 && dy.abs() < 0.01) return;

    onMove(dx, dy);
    _lastSent = now;
  }

  void setActive(bool value) {
    _active = value;
    if (!value) {
      _smoothGyroX = 0;
      _smoothGyroY = 0;
      _smoothAccelX = 0;
      _smoothAccelY = 0;
      _gyroContribX = 0;
      _gyroContribY = 0;
      _accelContribX = 0;
      _accelContribY = 0;
      _lastGyroEvent = null;
      _lastAccelEvent = null;
    }
  }

  void stop() {
    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription = null;
    _accelSubscription = null;
    _active = false;
  }

  void updateSensitivity(double value) => sensitivity = value;
  void updateBlend(double value) => blendWeight = value;
  void updateMode(MovementMode newMode) => mode = newMode;
}