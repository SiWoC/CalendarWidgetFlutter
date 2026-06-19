import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'widget_constants.dart';
import 'widget_settings.dart';

/// Snapshot error written when refresh cannot produce calendar data.
class CalendarWidgetError {
  const CalendarWidgetError({required this.code, required this.message});

  final String code;
  final String message;

  factory CalendarWidgetError.fromJson(Map<String, dynamic> json) {
    return CalendarWidgetError(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'message': message};
}

/// One event line in the widget snapshot.
class CalendarEvent {
  const CalendarEvent({
    required this.color,
    required this.fontSize,
    required this.title,
    required this.isAllDay,
    this.time,
    this.location,
  });

  final String color;
  final int fontSize;
  final String? time;
  final String title;
  final String? location;
  final bool isAllDay;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      color: json['color'] as String,
      fontSize: json['fontsize'] as int,
      time: json['time'] as String?,
      title: json['title'] as String,
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'color': color,
      'fontsize': fontSize,
      'title': title,
      'isAllDay': isAllDay,
    };
    if (time != null) {
      json['time'] = time;
    }
    if (location != null) {
      json['location'] = location;
    }
    return json;
  }
}

/// Day grouping (`VANDAAG`, `MORGEN`, or formatted date).
class CalendarSection {
  const CalendarSection({required this.title, required this.events});

  final String title;
  final List<CalendarEvent> events;

  factory CalendarSection.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>;
    return CalendarSection(
      title: json['title'] as String,
      events: rawEvents
          .map((event) => CalendarEvent.fromJson(event as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'events': events.map((event) => event.toJson()).toList(),
  };
}

/// Render snapshot stored under [WidgetConstants.KEY_CALENDAR_WIDGET_DATA].
///
/// Display values are copied from [WidgetSettings] when *building* snapshots
/// (worker, [CalendarWidgetData.error]). [fromJson] expects a complete JSON
/// contract — missing fields are a writer bug.
class CalendarWidgetData {
  const CalendarWidgetData({
    required this.schemaVersion,
    this.error,
    required this.headerDate,
    required this.headerColor,
    required this.headerFontSize,
    required this.sections,
  });

  final int schemaVersion;
  final CalendarWidgetError? error;
  final String headerDate;
  final String headerColor;
  final int headerFontSize;
  final List<CalendarSection> sections;

  bool get hasError => error != null;

  bool get isEmpty =>
      sections.isEmpty || sections.every((section) => section.events.isEmpty);

  factory CalendarWidgetData.fromJson(Map<String, dynamic> json) {
    final rawError = json['error'];
    return CalendarWidgetData(
      schemaVersion: json['schemaVersion'] as int,
      error: rawError == null
          ? null
          : CalendarWidgetError.fromJson(rawError as Map<String, dynamic>),
      headerDate: json['headerDate'] as String,
      headerColor: json['headerColor'] as String,
      headerFontSize: json['headerFontsize'] as int,
      sections: (json['sections'] as List<dynamic>)
          .map(
            (section) =>
                CalendarSection.fromJson(section as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'error': error?.toJson(),
    'headerDate': headerDate,
    'headerColor': headerColor,
    'headerFontsize': headerFontSize,
    'sections': sections.map((section) => section.toJson()).toList(),
  };

  factory CalendarWidgetData.fromJsonString(String json) {
    return CalendarWidgetData.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// Fallback snapshot when refresh cannot read calendars.
  factory CalendarWidgetData.error({
    required String code,
    required String message,
    required WidgetSettings settings,
    String headerDate = '',
  }) {
    return CalendarWidgetData(
      schemaVersion: WidgetConstants.SCHEMA_VERSION,
      error: CalendarWidgetError(code: code, message: message),
      headerDate: headerDate,
      headerColor: settings.headerColor,
      headerFontSize: settings.headerFontSize,
      sections: const [],
    );
  }

  static Future<SharedPreferencesWithCache> _prefs() {
    return SharedPreferencesWithCache.create(
      sharedPreferencesOptions: const SharedPreferencesAsyncAndroidOptions(
        backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(
          fileName: WidgetConstants.PREFS_NAME,
        ),
      ),
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {WidgetConstants.KEY_CALENDAR_WIDGET_DATA},
      ),
    );
  }

  /// Reads the snapshot written by [CalendarRefreshWorker] (Kotlin).
  static Future<CalendarWidgetData?> loadFromPrefs() async {
    final prefs = await _prefs();
    final json = prefs.getString(WidgetConstants.KEY_CALENDAR_WIDGET_DATA);
    if (json == null || json.isEmpty) {
      return null;
    }
    return CalendarWidgetData.fromJsonString(json);
  }

  Future<void> saveToPrefs() async {
    final prefs = await _prefs();
    await prefs.setString(
      WidgetConstants.KEY_CALENDAR_WIDGET_DATA,
      toJsonString(),
    );
  }
}
