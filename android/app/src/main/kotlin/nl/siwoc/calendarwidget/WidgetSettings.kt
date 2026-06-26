package nl.siwoc.calendarwidget

import android.content.Context

data class WidgetSettings(
    val headerColor: String = WidgetConstants.DEFAULT_HEADER_COLOR,
    val headerFontSize: Int = WidgetConstants.DEFAULT_HEADER_FONT_SIZE,
    val eventFontSize: Int = WidgetConstants.DEFAULT_EVENT_FONT_SIZE,
    val fetchDays: Int = WidgetConstants.DEFAULT_FETCH_DAYS,
    val locale: String = WidgetConstants.DEFAULT_LOCALE,
    val backgroundColor: String = WidgetConstants.DEFAULT_BACKGROUND_COLOR,
    val backgroundOpacity: Int = WidgetConstants.DEFAULT_BACKGROUND_OPACITY,
    /** Parsed from CSV in prefs; empty = include all visible calendars. */
    val selectedCalendarIds: Set<Long> = emptySet(),
) {
    fun save(context: Context) {
        context.getSharedPreferences(WidgetConstants.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(WidgetConstants.KEY_HEADER_COLOR, headerColor)
            .putInt(WidgetConstants.KEY_HEADER_FONT_SIZE, headerFontSize)
            .putInt(WidgetConstants.KEY_EVENT_FONT_SIZE, eventFontSize)
            .putInt(WidgetConstants.KEY_FETCH_DAYS, fetchDays)
            .putString(WidgetConstants.KEY_LOCALE, locale)
            .putString(WidgetConstants.KEY_BACKGROUND_COLOR, backgroundColor)
            .putInt(WidgetConstants.KEY_BACKGROUND_OPACITY, backgroundOpacity)
            .putString(
                WidgetConstants.KEY_SELECTED_CALENDAR_IDS,
                encodeCalendarIds(selectedCalendarIds),
            )
            .apply()
    }

    companion object {
        fun load(context: Context): WidgetSettings {
            val prefs = context.getSharedPreferences(
                WidgetConstants.PREFS_NAME,
                Context.MODE_PRIVATE,
            )
            return WidgetSettings(
                headerColor = prefs.getString(
                    WidgetConstants.KEY_HEADER_COLOR,
                    WidgetConstants.DEFAULT_HEADER_COLOR,
                ) ?: WidgetConstants.DEFAULT_HEADER_COLOR,
                headerFontSize = prefs.getIntCompat(
                    WidgetConstants.KEY_HEADER_FONT_SIZE,
                    WidgetConstants.DEFAULT_HEADER_FONT_SIZE,
                ),
                eventFontSize = prefs.getIntCompat(
                    WidgetConstants.KEY_EVENT_FONT_SIZE,
                    WidgetConstants.DEFAULT_EVENT_FONT_SIZE,
                ),
                fetchDays = prefs.getIntCompat(
                    WidgetConstants.KEY_FETCH_DAYS,
                    WidgetConstants.DEFAULT_FETCH_DAYS,
                ),
                locale = prefs.getString(
                    WidgetConstants.KEY_LOCALE,
                    WidgetConstants.DEFAULT_LOCALE,
                ) ?: WidgetConstants.DEFAULT_LOCALE,
                backgroundColor = prefs.getString(
                    WidgetConstants.KEY_BACKGROUND_COLOR,
                    WidgetConstants.DEFAULT_BACKGROUND_COLOR,
                ) ?: WidgetConstants.DEFAULT_BACKGROUND_COLOR,
                backgroundOpacity = prefs.getIntCompat(
                    WidgetConstants.KEY_BACKGROUND_OPACITY,
                    WidgetConstants.DEFAULT_BACKGROUND_OPACITY,
                ),
                selectedCalendarIds = decodeCalendarIds(
                    prefs.getString(WidgetConstants.KEY_SELECTED_CALENDAR_IDS, ""),
                ),
            )
        }
    }
}

private fun encodeCalendarIds(ids: Set<Long>): String =
    ids.sorted().joinToString(",")

private fun decodeCalendarIds(value: String?): Set<Long> {
    if (value.isNullOrBlank()) return emptySet()
    return value.split(',')
        .mapNotNull { part ->
            part.trim().takeIf { it.isNotEmpty() }?.toLongOrNull()
        }
        .toSet()
}
