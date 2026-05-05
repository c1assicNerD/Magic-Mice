import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class GyroscopeService {
  StreamSubscription<GyroscopeEvent>? _subscription;

  double sensitivity = 5.0;
  final double _magnitudeThreshold = 0.03;
  final Duration _minInterval = const Duration(milliseconds: 16); // ~60Hz

  bool _active = false;
  double _accX = 0;
  double _accY = 0;

  // EMA smoothed values
  double _smoothX = 0;
  double _smoothY = 0;

  // EMA factor — lower = smoother but more lag, higher = more responsive
  // 0.2 is a good starting point, tune between 0.1 and 0.4
  final double _alpha = 0.2;

  DateTime? _lastSent;
  DateTime? _lastEvent;

  final void Function(double dx, double dy) onMove;

  GyroscopeService({required this.onMove});

  void start() {
    _subscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_processEvent);
  }

  void _processEvent(GyroscopeEvent event) {
    if (!_active) return;

    final now = DateTime.now();

    // Calculate time delta since last event (in seconds)
    double dt = 0.02; // default fallback ~50Hz
    if (_lastEvent != null) {
      dt = now.difference(_lastEvent!).inMicroseconds / 1000000.0;
      dt = dt.clamp(0.001, 0.1); // prevent extreme values
    }
    _lastEvent = now;

    double rawX = event.y;
    double rawY = event.x;

    // Dead zone check
    double magnitude = (rawX * rawX + rawY * rawY);
    if (magnitude < _magnitudeThreshold) {
      // Decay smoothed values toward zero when idle
      _smoothX *= 0.8;
      _smoothY *= 0.8;

      // Stop sending when motion is negligible
      if (_smoothX.abs() < 0.01 && _smoothY.abs() < 0.01) return;
    } else {
      // Apply EMA smoothing
      _smoothX = (_alpha * rawX) + ((1 - _alpha) * _smoothX);
      _smoothY = (_alpha * rawY) + ((1 - _alpha) * _smoothY);
    }

    // Scale by sensitivity and time delta for frame-rate independence
    _accX = _smoothX * sensitivity * dt * 100;
    _accY = _smoothY * sensitivity * dt * 100;

    // Throttle to 60Hz
    if (_lastSent != null &&
        now.difference(_lastSent!) < _minInterval) return;

    onMove(_accX, _accY);
    _lastSent = now;
  }

  void setActive(bool value) {
    _active = value;
    if (!value) {
      // Reset smoothing state on release
      _smoothX = 0;
      _smoothY = 0;
      _accX = 0;
      _accY = 0;
      _lastEvent = null;
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _active = false;
    _smoothX = 0;
    _smoothY = 0;
    _accX = 0;
    _accY = 0;
  }

  void updateSensitivity(double value) => sensitivity = value;
}