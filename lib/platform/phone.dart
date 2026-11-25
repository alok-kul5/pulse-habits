import 'package:material_ui/material_ui.dart';

import 'health.dart';
import 'reminders.dart';

/// The phone-only services in one place, so screens can ask what exists.
/// On the web demo every one of them reports itself as unsupported.
class Phone {
  Phone({Health? health, Reminders? reminders}) : health = health ?? Health(), reminders = reminders ?? Reminders();

  final Health health;
  final Reminders reminders;

  /// Health Connect status, refreshed when the app asks or comes back.
  final healthStatus = ValueNotifier<HealthStatus>(
    Health.platformSupported ? HealthStatus.notInstalled : HealthStatus.unsupported,
  );

  Future<HealthStatus> refreshHealth() async => healthStatus.value = await health.status();
}

class PhoneScope extends InheritedWidget {
  const PhoneScope({super.key, required this.phone, required super.child});

  final Phone phone;

  static Phone of(BuildContext context) => context.getInheritedWidgetOfExactType<PhoneScope>()!.phone;

  @override
  bool updateShouldNotify(PhoneScope old) => old.phone != phone;
}
