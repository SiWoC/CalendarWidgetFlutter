package nl.siwoc.calendarwidget

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Reads device calendars via [CalendarContract], builds [CalendarWidgetData],
 * and writes the snapshot to SharedPreferences.
 *
 * WorkManager and MethodChannel call [refresh] on the same code path.
 */
object CalendarRefreshWorker {

    fun refresh(context: Context): CalendarWidgetData {
        val settings = WidgetSettings.load(context)
        val headerDate = formatHeaderDate(context, settings)

        if (!hasCalendarPermission(context)) {
            return saveAndReturn(
                context,
                CalendarWidgetData.error(
                    code = WidgetConstants.ERROR_PERMISSION_DENIED,
                    message = Utils.stringForLocale(
                        context,
                        settings.locale,
                        R.string.error_permission_denied,
                    ),
                    settings = settings,
                    headerDate = headerDate,
                ),
            )
        }

        return try {
            val visibleCalendars = loadVisibleCalendars(context)
            if (visibleCalendars.isEmpty()) {
                return saveAndReturn(
                    context,
                    CalendarWidgetData.error(
                        code = WidgetConstants.ERROR_NO_CALENDARS,
                        message = Utils.stringForLocale(
                            context,
                            settings.locale,
                            R.string.error_no_calendars,
                        ),
                        settings = settings,
                        headerDate = headerDate,
                    ),
                )
            }

            val calendars = resolveCalendars(settings, visibleCalendars)
            if (calendars.isEmpty()) {
                return saveAndReturn(
                    context,
                    CalendarWidgetData.error(
                        code = WidgetConstants.ERROR_NO_CALENDARS,
                        message = Utils.stringForLocale(
                            context,
                            settings.locale,
                            R.string.error_no_calendars_selected,
                        ),
                        settings = settings,
                        headerDate = headerDate,
                    ),
                )
            }

            val calendarIds = calendars.map { it.id }.toSet()
            val calendarColors = calendars.associate { it.id to it.color }
            val range = dayRange(settings.fetchDays)
            val instances = queryInstances(
                context = context,
                calendarIds = calendarIds,
                rangeStartMillis = range.first,
                rangeEndMillis = range.second,
            )

            val locale = localeFromSettings(settings)
            val sections = buildSections(
                context = context,
                instances = instances,
                settings = settings,
                locale = locale,
                fetchDays = settings.fetchDays,
                calendarColors = calendarColors,
            )

            saveAndReturn(
                context,
                CalendarWidgetData(
                    schemaVersion = WidgetConstants.SCHEMA_VERSION,
                    error = null,
                    headerDate = headerDate,
                    headerColor = settings.headerColor,
                    headerFontSize = settings.headerFontSize,
                    sections = sections,
                ),
            )
        } catch (exception: Exception) {
            saveAndReturn(
                context,
                CalendarWidgetData.error(
                    code = WidgetConstants.ERROR_UNKNOWN,
                    message = exception.message ?: Utils.stringForLocale(
                        context,
                        settings.locale,
                        R.string.error_unknown,
                    ),
                    settings = settings,
                    headerDate = headerDate,
                ),
            )
        }
    }

    private fun saveAndReturn(context: Context, data: CalendarWidgetData): CalendarWidgetData {
        data.save(context)
        CalendarWidgetUpdater.requestUpdate(context)
        return data
    }

    private fun hasCalendarPermission(context: Context): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    private fun localeFromSettings(settings: WidgetSettings): Locale =
        Locale.forLanguageTag(settings.locale)

    private fun formatHeaderDate(context: Context, settings: WidgetSettings): String {
        val locale = localeFromSettings(settings)
        val pattern = Utils.stringForLocale(context, settings.locale, R.string.date_format_header)
        val formatter = SimpleDateFormat(pattern, locale)
        return formatter.format(Date()).replaceFirstChar { char ->
            if (char.isLowerCase()) char.titlecase(locale) else char.toString()
        }
    }

    private fun formatSectionTitle(
        context: Context,
        settings: WidgetSettings,
        dayOffset: Int,
        date: Calendar,
        locale: Locale,
    ): String {
        if (dayOffset == 0) {
            return Utils.stringForLocale(context, settings.locale, R.string.section_today)
        }
        if (dayOffset == 1) {
            return Utils.stringForLocale(context, settings.locale, R.string.section_tomorrow)
        }
        val pattern = Utils.stringForLocale(context, settings.locale, R.string.date_format_section)
        val formatter = SimpleDateFormat(pattern, locale)
        return formatter.format(date.time).replaceFirstChar { char ->
            if (char.isLowerCase()) char.titlecase(locale) else char.toString()
        }
    }

    private fun dayRange(fetchDays: Int): Pair<Long, Long> {
        val today = dayCalendar(offsetDays = 0)
        val start = today.timeInMillis
        val end = startOfDay(today, offsetDays = fetchDays)
        return start to end
    }

    private fun startOfDay(day: Calendar, offsetDays: Int): Long {
        val copy = day.clone() as Calendar
        copy.add(Calendar.DAY_OF_YEAR, offsetDays)
        copy.set(Calendar.HOUR_OF_DAY, 0)
        copy.set(Calendar.MINUTE, 0)
        copy.set(Calendar.SECOND, 0)
        copy.set(Calendar.MILLISECOND, 0)
        return copy.timeInMillis
    }

    private fun dayCalendar(offsetDays: Int): Calendar = startOfDayCalendar(offsetDays)

    private fun startOfDayCalendar(offsetDays: Int): Calendar {
        val day = Calendar.getInstance()
        day.add(Calendar.DAY_OF_YEAR, offsetDays)
        day.set(Calendar.HOUR_OF_DAY, 0)
        day.set(Calendar.MINUTE, 0)
        day.set(Calendar.SECOND, 0)
        day.set(Calendar.MILLISECOND, 0)
        return day
    }

    private data class VisibleCalendar(
        val id: Long,
        val color: Int,
    )

    private fun resolveCalendars(
        settings: WidgetSettings,
        visibleCalendars: List<VisibleCalendar>,
    ): List<VisibleCalendar> {
        if (settings.selectedCalendarIds.isEmpty()) {
            return visibleCalendars
        }
        return visibleCalendars.filter { it.id in settings.selectedCalendarIds }
    }

    private fun loadVisibleCalendars(context: Context): List<VisibleCalendar> {
        val calendars = mutableListOf<VisibleCalendar>()
        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_COLOR,
            ),
            "${CalendarContract.Calendars.VISIBLE} = ?",
            arrayOf("1"),
            null,
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
            val colorColumn = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR)
            while (cursor.moveToNext()) {
                calendars.add(
                    VisibleCalendar(
                        id = cursor.getLong(idColumn),
                        color = cursor.getInt(colorColumn),
                    ),
                )
            }
        }
        return calendars
    }

    private fun queryInstances(
        context: Context,
        calendarIds: Set<Long>,
        rangeStartMillis: Long,
        rangeEndMillis: Long,
    ): List<CalendarInstance> {
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().also { builder ->
            ContentUris.appendId(builder, rangeStartMillis)
            ContentUris.appendId(builder, rangeEndMillis)
        }.build()

        val placeholders = calendarIds.joinToString(",") { "?" }
        val selection = "${CalendarContract.Instances.CALENDAR_ID} IN ($placeholders)"
        val selectionArgs = calendarIds.map { it.toString() }.toTypedArray()

        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.DISPLAY_COLOR,
            CalendarContract.Instances.CALENDAR_ID,
        )

        val instances = mutableListOf<CalendarInstance>()
        context.contentResolver.query(
            uri,
            projection,
            selection,
            selectionArgs,
            "${CalendarContract.Instances.BEGIN} ASC",
        )?.use { cursor ->
            val eventIdColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID)
            val beginColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN)
            val endColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.END)
            val titleColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE)
            val locationColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_LOCATION)
            val allDayColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)
            val displayColorColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.DISPLAY_COLOR)
            val calendarIdColumn = cursor.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_ID)

            while (cursor.moveToNext()) {
                val title = cursor.getString(titleColumn).orEmpty()
                val location = cursor.getString(locationColumn)?.takeIf { it.isNotBlank() }
                instances.add(
                    CalendarInstance(
                        eventId = cursor.getLong(eventIdColumn),
                        begin = cursor.getLong(beginColumn),
                        end = cursor.getLong(endColumn),
                        title = title,
                        location = location,
                        isAllDay = cursor.getInt(allDayColumn) == 1,
                        displayColor = cursor.getInt(displayColorColumn),
                        calendarId = cursor.getLong(calendarIdColumn),
                    ),
                )
            }
        }
        return instances
    }

    private fun buildSections(
        context: Context,
        instances: List<CalendarInstance>,
        settings: WidgetSettings,
        locale: Locale,
        fetchDays: Int,
        calendarColors: Map<Long, Int>,
    ): List<CalendarSection> {
        val sections = mutableListOf<CalendarSection>()

        for (dayOffset in 0 until fetchDays) {
            val day = dayCalendar(dayOffset)
            val dayStart = day.timeInMillis
            val dayEnd = startOfDay(day, offsetDays = 1) - 1
            val title = formatSectionTitle(context, settings, dayOffset, day, locale)

            val dayEvents = instances
                .filter { instance -> instance.overlapsDay(dayStart, dayEnd) }
                .sortedWith(
                    compareBy<CalendarInstance> { !it.isAllDay }.thenBy { it.begin },
                )
                .map { instance ->
                    instance.toWidgetEvent(
                        settings = settings,
                        locale = locale,
                        dayStart = dayStart,
                        dayEnd = dayEnd,
                        calendarColors = calendarColors,
                    )
                }

            sections.add(CalendarSection(title = title, events = dayEvents))
        }

        return sections
    }

    private data class CalendarInstance(
        val eventId: Long,
        val begin: Long,
        val end: Long,
        val title: String,
        val location: String?,
        val isAllDay: Boolean,
        val displayColor: Int,
        val calendarId: Long,
    ) {
        fun overlapsDay(dayStart: Long, dayEnd: Long): Boolean {
            if (isAllDay) {
                // All-day instants are UTC midnights with exclusive end; compare local dates.
                val timeZone = TimeZone.getDefault()
                val eventStart = truncateToLocalDate(begin, timeZone)
                val eventEndExclusive = truncateToLocalDate(end, timeZone)
                val target = truncateToLocalDate(dayStart, timeZone)
                return !target.before(eventStart) && target.before(eventEndExclusive)
            }
            return begin < dayEnd && end > dayStart && end >= Calendar.getInstance().timeInMillis
        }

        fun toWidgetEvent(
            settings: WidgetSettings,
            locale: Locale,
            dayStart: Long,
            dayEnd: Long,
            calendarColors: Map<Long, Int>,
        ): CalendarEvent {
            val colorArgb = when {
                displayColor != 0 -> displayColor
                else -> calendarColors[calendarId] ?: 0xFF000000.toInt()
            }
            return CalendarEvent(
                color = Utils.argbToHex(colorArgb),
                fontSize = settings.eventFontSize,
                title = title,
                isAllDay = isAllDay,
                time = if (isAllDay) {
                    null
                } else {
                    formatEventTime(begin, end, dayStart, dayEnd, locale)
                },
                location = location,
            )
        }
    }

    private fun truncateToLocalDate(millis: Long, timeZone: TimeZone): Calendar {
        val calendar = Calendar.getInstance(timeZone)
        calendar.timeInMillis = millis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar
    }

    private fun formatEventTime(
        begin: Long,
        end: Long,
        dayStart: Long,
        dayEnd: Long,
        locale: Locale,
    ): String {
        val clippedBegin = maxOf(begin, dayStart)
        val clippedEnd = minOf(end, dayEnd)
        val formatter = SimpleDateFormat("HH:mm", locale)
        return "${formatter.format(Date(clippedBegin))}-${formatter.format(Date(clippedEnd))}"
    }
}
