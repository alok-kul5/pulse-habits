import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/days.dart';

enum HealthStatus {
  /// Not Android (the web demo): Health Connect doesn't exist here.
  unsupported,

  /// Android, but Health Connect isn't installed or needs an update.
  notInstalled,

  /// Installed; Pulse hasn't been allowed to read steps yet.
  denied,

  /// Pulse can read steps.
  granted,
}

/// Steps from Health Connect, read-only, through a small Kotlin bridge
/// (`android/app/src/main/kotlin/dev/alok/pulse/HealthBridge.kt`).
/// Nothing is written back and nothing leaves the phone.
class Health {
  Health({MethodChannel? channel}) : _ch = channel ?? const MethodChannel('pulse/health');

  final MethodChannel _ch;

  static bool get platformSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<HealthStatus> status() async {
    if (!platformSupported) return HealthStatus.unsupported;
    try {
      final s = await _ch.invokeMethod<String>('status');
      return switch (s) {
        'granted' => HealthStatus.granted,
        'denied' => HealthStatus.denied,
        _ => HealthStatus.notInstalled,
      };
    } catch (_) {
      return HealthStatus.notInstalled;
    }
  }

  /// Shows Health Connect's own permission screen. True if steps were allowed.
  Future<bool> request() async {
    if (!platformSupported) return false;
    try {
      return await _ch.invokeMethod<bool>('request') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Health Connect to install or update it.
  Future<void> install() async {
    if (!platformSupported) return;
    try {
      await _ch.invokeMethod('install');
    } catch (_) {}
  }

  /// Daily step totals for the last [days] days, keyed by [Days] number.
  Future<Map<int, int>> steps(int days) async {
    if (!platformSupported) return {};
    try {
      final raw = await _ch.invokeMapMethod<String, int>('steps', {'days': days}) ?? {};
      // Keys are ISO dates ("2026-11-25") in the phone's time zone.
      return {for (final e in raw.entries) Days.of(DateTime.parse(e.key)): e.value};
    } catch (_) {
      return {};
    }
  }

  /// True if Android opened the app from Health Connect's "why does Pulse
  /// need this?" link, so the app should show its explainer.
  Future<bool> openedForRationale() async {
    if (!platformSupported) return false;
    try {
      return await _ch.invokeMethod<bool>('openedForRationale') ?? false;
    } catch (_) {
      return false;
    }
  }
}
