import 'package:permission_handler/permission_handler.dart';

/// Runtime calendar access for [CalendarRefreshWorker] on Android.
abstract final class CalendarPermission {
  static Permission get _access => Permission.calendarFullAccess;

  static Future<PermissionStatus> status() => _access.status;

  static Future<bool> get isGranted async => (await status()).isGranted;

  static Future<bool> get isPermanentlyDenied async =>
      (await status()).isPermanentlyDenied;

  /// Shows the system dialog when still requestable; returns whether access was granted.
  static Future<bool> ensureGranted() async {
    var current = await status();
    if (current.isGranted) {
      return true;
    }
    if (current.isDenied) {
      current = await _access.request();
      return current.isGranted;
    }
    return false;
  }

  static Future<bool> openSettings() => openAppSettings();
}
