import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'widget_constants.dart';

/// User-configurable widget options (mirror [WidgetSettings.kt]).
class WidgetSettings {
  const WidgetSettings({
    this.headerColor = WidgetConstants.DEFAULT_HEADER_COLOR,
    this.headerFontSize = WidgetConstants.DEFAULT_HEADER_FONT_SIZE,
    this.eventFontSize = WidgetConstants.DEFAULT_EVENT_FONT_SIZE,
    this.fetchDays = WidgetConstants.DEFAULT_FETCH_DAYS,
    this.locale = WidgetConstants.DEFAULT_LOCALE,
    this.backgroundColor = WidgetConstants.DEFAULT_BACKGROUND_COLOR,
    this.backgroundOpacity = WidgetConstants.DEFAULT_BACKGROUND_OPACITY,
    this.selectedCalendarIds = const {},
  });

  final String headerColor;
  final int headerFontSize;
  final int eventFontSize;
  final int fetchDays;
  final String locale;
  final String backgroundColor;

  /// 0–100; applied over [backgroundColor] at render time.
  final int backgroundOpacity;

  /// Parsed from CSV in prefs; empty = include all visible calendars.
  final Set<int> selectedCalendarIds;

  static Future<SharedPreferencesWithCache> _prefs() {
    return SharedPreferencesWithCache.create(
      sharedPreferencesOptions: const SharedPreferencesAsyncAndroidOptions(
        backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
          fileName: WidgetConstants.PREFS_NAME,
        ),
      ),
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          WidgetConstants.KEY_HEADER_COLOR,
          WidgetConstants.KEY_HEADER_FONT_SIZE,
          WidgetConstants.KEY_EVENT_FONT_SIZE,
          WidgetConstants.KEY_FETCH_DAYS,
          WidgetConstants.KEY_LOCALE,
          WidgetConstants.KEY_SELECTED_CALENDAR_IDS,
          WidgetConstants.KEY_BACKGROUND_COLOR,
          WidgetConstants.KEY_BACKGROUND_OPACITY,
        },
      ),
    );
  }

  static Future<WidgetSettings> load() async {
    final prefs = await _prefs();
    return WidgetSettings(
      headerColor:
          prefs.getString(WidgetConstants.KEY_HEADER_COLOR) ??
          WidgetConstants.DEFAULT_HEADER_COLOR,
      headerFontSize:
          prefs.getInt(WidgetConstants.KEY_HEADER_FONT_SIZE) ??
          WidgetConstants.DEFAULT_HEADER_FONT_SIZE,
      eventFontSize:
          prefs.getInt(WidgetConstants.KEY_EVENT_FONT_SIZE) ??
          WidgetConstants.DEFAULT_EVENT_FONT_SIZE,
      fetchDays:
          prefs.getInt(WidgetConstants.KEY_FETCH_DAYS) ??
          WidgetConstants.DEFAULT_FETCH_DAYS,
      locale:
          prefs.getString(WidgetConstants.KEY_LOCALE) ??
          WidgetConstants.DEFAULT_LOCALE,
      backgroundColor:
          prefs.getString(WidgetConstants.KEY_BACKGROUND_COLOR) ??
          WidgetConstants.DEFAULT_BACKGROUND_COLOR,
      backgroundOpacity:
          prefs.getInt(WidgetConstants.KEY_BACKGROUND_OPACITY) ??
          WidgetConstants.DEFAULT_BACKGROUND_OPACITY,
      selectedCalendarIds: _decodeCalendarIds(
        prefs.getString(WidgetConstants.KEY_SELECTED_CALENDAR_IDS),
      ),
    );
  }

  Future<void> save() async {
    final prefs = await _prefs();
    await prefs.setString(WidgetConstants.KEY_HEADER_COLOR, headerColor);
    await prefs.setInt(WidgetConstants.KEY_HEADER_FONT_SIZE, headerFontSize);
    await prefs.setInt(WidgetConstants.KEY_EVENT_FONT_SIZE, eventFontSize);
    await prefs.setInt(WidgetConstants.KEY_FETCH_DAYS, fetchDays);
    await prefs.setString(WidgetConstants.KEY_LOCALE, locale);
    await prefs.setString(WidgetConstants.KEY_BACKGROUND_COLOR, backgroundColor);
    await prefs.setInt(
      WidgetConstants.KEY_BACKGROUND_OPACITY,
      backgroundOpacity,
    );
    await prefs.setString(
      WidgetConstants.KEY_SELECTED_CALENDAR_IDS,
      _encodeCalendarIds(selectedCalendarIds),
    );
  }

  WidgetSettings copyWith({
    String? headerColor,
    int? headerFontSize,
    int? eventFontSize,
    int? fetchDays,
    String? locale,
    String? backgroundColor,
    int? backgroundOpacity,
    Set<int>? selectedCalendarIds,
  }) {
    return WidgetSettings(
      headerColor: headerColor ?? this.headerColor,
      headerFontSize: headerFontSize ?? this.headerFontSize,
      eventFontSize: eventFontSize ?? this.eventFontSize,
      fetchDays: fetchDays ?? this.fetchDays,
      locale: locale ?? this.locale,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
    );
  }

  static String _encodeCalendarIds(Set<int> ids) {
    final sorted = ids.toList()..sort();
    return sorted.join(',');
  }

  static Set<int> _decodeCalendarIds(String? value) {
    if (value == null || value.isEmpty) return {};
    final ids = <int>{};
    for (final part in value.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final id = int.tryParse(trimmed);
      if (id != null) ids.add(id);
    }
    return ids;
  }
}
