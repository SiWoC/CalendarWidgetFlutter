package nl.siwoc.calendarwidget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Snapshot error written when refresh cannot produce calendar data. */
data class CalendarWidgetError(
    val code: String,
    val message: String,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("code", code)
        .put("message", message)

    companion object {
        fun fromJson(json: JSONObject): CalendarWidgetError = CalendarWidgetError(
            code = json.getString("code"),
            message = json.getString("message"),
        )
    }
}

/** One event line in the widget snapshot. */
data class CalendarEvent(
    val color: String,
    val fontSize: Int,
    val title: String,
    val isAllDay: Boolean,
    val time: String? = null,
    val location: String? = null,
) {
    fun toJson(): JSONObject {
        val json = JSONObject()
            .put("color", color)
            .put("fontsize", fontSize)
            .put("title", title)
            .put("isAllDay", isAllDay)
        time?.let { json.put("time", it) }
        location?.let { json.put("location", it) }
        return json
    }

    companion object {
        fun fromJson(json: JSONObject): CalendarEvent = CalendarEvent(
            color = json.getString("color"),
            fontSize = json.getInt("fontsize"),
            title = json.getString("title"),
            isAllDay = json.getBoolean("isAllDay"),
            time = json.optString("time").takeIf { json.has("time") },
            location = json.optString("location").takeIf { json.has("location") },
        )
    }
}

/** Day grouping (`VANDAAG`, `MORGEN`, or formatted date). */
data class CalendarSection(
    val title: String,
    val events: List<CalendarEvent>,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("title", title)
        .put("events", JSONArray().apply { events.forEach { put(it.toJson()) } })

    companion object {
        fun fromJson(json: JSONObject): CalendarSection {
            val rawEvents = json.getJSONArray("events")
            val events = buildList {
                for (index in 0 until rawEvents.length()) {
                    add(CalendarEvent.fromJson(rawEvents.getJSONObject(index)))
                }
            }
            return CalendarSection(
                title = json.getString("title"),
                events = events,
            )
        }
    }
}

/**
 * Render snapshot stored under [WidgetConstants.KEY_CALENDAR_WIDGET_DATA].
 *
 * Display values are copied from [WidgetSettings] when *building* snapshots
 * (worker, [error]). [fromJson] expects a complete JSON contract — missing
 * fields are a writer bug.
 */
data class CalendarWidgetData(
    val schemaVersion: Int,
    val error: CalendarWidgetError?,
    val headerDate: String,
    val headerColor: String,
    val headerFontSize: Int,
    val sections: List<CalendarSection>,
) {
    val hasError: Boolean
        get() = error != null

    val isEmpty: Boolean
        get() = sections.isEmpty() || sections.all { it.events.isEmpty() }

    fun toJson(): JSONObject {
        val json = JSONObject()
            .put("schemaVersion", schemaVersion)
            .put("headerDate", headerDate)
            .put("headerColor", headerColor)
            .put("headerFontsize", headerFontSize)
            .put(
                "sections",
                JSONArray().apply { sections.forEach { put(it.toJson()) } },
            )
        error?.let { json.put("error", it.toJson()) } ?: json.put("error", JSONObject.NULL)
        return json
    }

    fun toJsonString(): String = toJson().toString()

    fun save(context: Context) {
        context.getSharedPreferences(WidgetConstants.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(WidgetConstants.KEY_CALENDAR_WIDGET_DATA, toJsonString())
            .apply()
    }

    companion object {
        fun fromJson(json: JSONObject): CalendarWidgetData {
            val rawSections = json.getJSONArray("sections")
            val sections = buildList {
                for (index in 0 until rawSections.length()) {
                    add(CalendarSection.fromJson(rawSections.getJSONObject(index)))
                }
            }
            val rawError = json.opt("error")
            val error = when {
                rawError == null || rawError == JSONObject.NULL -> null
                else -> CalendarWidgetError.fromJson(rawError as JSONObject)
            }
            return CalendarWidgetData(
                schemaVersion = json.getInt("schemaVersion"),
                error = error,
                headerDate = json.getString("headerDate"),
                headerColor = json.getString("headerColor"),
                headerFontSize = json.getInt("headerFontsize"),
                sections = sections,
            )
        }

        fun fromJsonString(json: String): CalendarWidgetData =
            fromJson(JSONObject(json))

        fun load(context: Context): CalendarWidgetData? {
            val json = context.getSharedPreferences(WidgetConstants.PREFS_NAME, Context.MODE_PRIVATE)
                .getString(WidgetConstants.KEY_CALENDAR_WIDGET_DATA, null)
            if (json.isNullOrBlank()) return null
            return fromJsonString(json)
        }

        /** Fallback snapshot when refresh cannot read calendars. */
        fun error(
            code: String,
            message: String,
            settings: WidgetSettings,
            headerDate: String = "",
        ): CalendarWidgetData = CalendarWidgetData(
            schemaVersion = WidgetConstants.SCHEMA_VERSION,
            error = CalendarWidgetError(code = code, message = message),
            headerDate = headerDate,
            headerColor = settings.headerColor,
            headerFontSize = settings.headerFontSize,
            sections = emptyList(),
        )
    }
}
