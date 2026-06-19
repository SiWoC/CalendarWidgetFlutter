import 'package:flutter/services.dart';

import 'calendar_widget_data.dart';
import 'widget_constants.dart';

/// Flutter ↔ Kotlin bridge for calendar refresh (mirror [CalendarPlatformChannel.kt]).
abstract final class CalendarPlatformChannel {
  static const _channel = MethodChannel(WidgetConstants.METHOD_CHANNEL);

  static const methodRefresh = 'refresh';
  static const methodGetWallpaper = 'getWallpaper';

  /// Runs [CalendarRefreshWorker] on Android and returns the written snapshot.
  static Future<CalendarWidgetData> refresh() async {
    final json = await _channel.invokeMethod<String>(methodRefresh);
    if (json == null) {
      throw StateError('refresh returned null');
    }
    return CalendarWidgetData.fromJsonString(json);
  }

  /// Home-screen wallpaper PNG bytes for the in-app preview, or null if unavailable.
  static Future<Uint8List?> getWallpaper() async {
    final bytes = await _channel.invokeMethod<Uint8List>(methodGetWallpaper);
    return bytes;
  }
}
