package nl.siwoc.calendarwidget

import androidx.datastore.preferences.core.longPreferencesKey

/**
 * Glance-only keys ([androidx.glance.state.PreferencesGlanceStateDefinition]).
 *
 * [REDRAW_AT] is bumped on every [CalendarWidgetUpdater.requestUpdate] so Glance
 * recomposes while a session is active. Display data still comes from
 * SharedPreferences ([WidgetSettings], [CalendarWidgetData]); this does not
 * duplicate or fix settings — it only forces a redraw.
 */
object WidgetGlanceState {
    val REDRAW_AT = longPreferencesKey("redraw_at")
}
