package nl.siwoc.calendarwidget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Requests a Glance redraw after the worker writes a new snapshot. */
object CalendarWidgetUpdater {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    fun requestUpdate(context: Context) {
        val appContext = context.applicationContext
        scope.launch {
            val manager = GlanceAppWidgetManager(appContext)
            manager.getGlanceIds(CalendarWidget::class.java).forEach { glanceId ->
                CalendarWidget().update(appContext, glanceId)
            }
        }
    }
}
