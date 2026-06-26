import 'package:flutter/services.dart';

import 'calendar_widget_data.dart';
import 'widget_constants.dart';

/// Flutter ↔ Kotlin bridge for calendar refresh (mirror [CalendarPlatformChannel.kt]).
abstract final class CalendarPlatformChannel {
  static const _channel = MethodChannel(WidgetConstants.METHOD_CHANNEL);

  static const METHOD_REFRESH = 'refresh';
  static const METHOD_SCHEDULE_PERIODIC_REFRESH = 'schedulePeriodicRefresh';
  static const METHOD_GET_WALLPAPER = 'getWallpaper';

  /// Runs [CalendarRefreshWorker] on Android and returns the written snapshot.
  static Future<CalendarWidgetData> refresh() async {
    final json = await _channel.invokeMethod<String>(METHOD_REFRESH);
    if (json == null) {
      throw StateError('refresh returned null');
    }
    return CalendarWidgetData.fromJsonString(json);
  }

  /// Registers or updates the 30-minute WorkManager periodic refresh job.
  static Future<void> schedulePeriodicRefresh() async {
    await _channel.invokeMethod<void>(METHOD_SCHEDULE_PERIODIC_REFRESH);
  }

  /// Home-screen wallpaper PNG bytes for the in-app preview, or null if unavailable.
  static Future<Uint8List?> getWallpaper() async {
    final bytes = await _channel.invokeMethod<Uint8List>(METHOD_GET_WALLPAPER);
    return bytes;
  }
}
