/// Shared preference keys and defaults (mirror [WidgetConstants.kt]).
abstract final class WidgetConstants {
  static const PREFS_NAME = 'nl.siwoc.calendarwidget';

  static const KEY_CALENDAR_WIDGET_DATA = 'calendar_widget_data';

  static const KEY_HEADER_COLOR = 'header_color';
  static const KEY_HEADER_FONT_SIZE = 'header_font_size';
  static const KEY_EVENT_FONT_SIZE = 'event_font_size';
  static const KEY_FETCH_DAYS = 'fetch_days';
  static const KEY_LOCALE = 'locale';
  static const KEY_SELECTED_CALENDAR_IDS = 'selected_calendar_ids';
  static const KEY_BACKGROUND_COLOR = 'background_color';
  static const KEY_BACKGROUND_OPACITY = 'background_opacity';

  static const METHOD_CHANNEL = 'nl.siwoc.calendarwidget/calendar';

  static const DEFAULT_HEADER_COLOR = '#FF000000';
  static const DEFAULT_HEADER_FONT_SIZE = 14;
  static const DEFAULT_EVENT_FONT_SIZE = 14;
  static const DEFAULT_FETCH_DAYS = 7;
  static const DEFAULT_LOCALE = 'nl-NL';
  static const DEFAULT_BACKGROUND_COLOR = '#4A4A4A4A';
  static const DEFAULT_BACKGROUND_OPACITY = 50;

  /// [CalendarWidgetData] JSON schema version.
  static const SCHEMA_VERSION = 1;

  /// [CalendarWidgetError.code] values written by the refresh worker.
  static const ERROR_PERMISSION_DENIED = 'permission_denied';
  static const ERROR_NO_CALENDARS = 'no_calendars';
  static const ERROR_UNKNOWN = 'unknown';
}
