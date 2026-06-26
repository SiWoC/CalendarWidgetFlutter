package nl.siwoc.calendarwidget

object WidgetConstants {
    const val PREFS_NAME = "nl.siwoc.calendarwidget"

    /** Snapshot JSON written by the worker; read by Glance and Flutter preview. */
    const val KEY_CALENDAR_WIDGET_DATA = "calendar_widget_data"

    const val KEY_HEADER_COLOR = "header_color"
    const val KEY_HEADER_FONT_SIZE = "header_font_size"
    const val KEY_EVENT_FONT_SIZE = "event_font_size"
    const val KEY_FETCH_DAYS = "fetch_days"
    const val KEY_LOCALE = "locale"
    const val KEY_SELECTED_CALENDAR_IDS = "selected_calendar_ids"
    const val KEY_BACKGROUND_COLOR = "background_color"
    const val KEY_BACKGROUND_OPACITY = "background_opacity"

    const val METHOD_CHANNEL = "nl.siwoc.calendarwidget/calendar"

    /** Unique name for [CalendarRefreshScheduler] periodic WorkManager job. */
    const val PERIODIC_REFRESH_WORK_NAME = "calendar_widget_periodic_refresh"

    /** Background calendar refresh interval (minutes). Android minimum is 15. */
    const val PERIODIC_REFRESH_INTERVAL_MINUTES = 30L

    // Readable hex; opaque black.
    const val DEFAULT_HEADER_COLOR = "#FF000000"
    const val DEFAULT_HEADER_FONT_SIZE = 14
    const val DEFAULT_EVENT_FONT_SIZE = 14
    const val DEFAULT_FETCH_DAYS = 7
    const val DEFAULT_LOCALE = "nl-NL"
    const val DEFAULT_BACKGROUND_COLOR = "#4A4A4A4A"
    const val DEFAULT_BACKGROUND_OPACITY = 30

    /** [CalendarWidgetData] JSON schema version. */
    const val SCHEMA_VERSION = 1

    /** [CalendarWidgetError.code] values written by the refresh worker. */
    const val ERROR_PERMISSION_DENIED = "permission_denied"
    const val ERROR_NO_CALENDARS = "no_calendars"
    const val ERROR_UNKNOWN = "unknown"
}
