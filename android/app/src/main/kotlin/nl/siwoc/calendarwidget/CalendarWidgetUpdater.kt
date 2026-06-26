package nl.siwoc.calendarwidget

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withContext

/** Requests a Glance redraw after the worker writes a new snapshot. */
object CalendarWidgetUpdater {
    private const val TAG = "CalendarWidgetUpdater"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val widget = CalendarWidget()
    private val updateMutex = Mutex()

    @Volatile
    private var anotherUpdateRequested = false

    fun requestUpdate(context: Context) {
        val appContext = context.applicationContext
        scope.launch {
            if (!updateMutex.tryLock()) {
                anotherUpdateRequested = true
                return@launch
            }
            try {
                do {
                    anotherUpdateRequested = false
                    performUpdate(appContext)
                } while (anotherUpdateRequested)
            } finally {
                updateMutex.unlock()
            }
        }
    }

    private suspend fun performUpdate(appContext: Context) {
        val manager = GlanceAppWidgetManager(appContext)
        val glanceIds = manager.getGlanceIds(CalendarWidget::class.java)
        Log.d(TAG, "requestUpdate: ${glanceIds.size} widget instance(s)")
        val settings = WidgetSettings.load(appContext)
        Log.d(
            TAG,
            "WidgetSettings.load (before update): backgroundColor=${settings.backgroundColor} " +
                "backgroundOpacity=${settings.backgroundOpacity}",
        )
        val redrawAt = System.currentTimeMillis()
        withContext(Dispatchers.Main) {
            glanceIds.forEach { glanceId ->
                updateAppWidgetState(appContext, glanceId) { prefs ->
                    prefs[WidgetGlanceState.REDRAW_AT] = redrawAt
                }
                widget.update(appContext, glanceId)
            }
        }
        Log.d(TAG, "force Glance redraw: redrawAt=$redrawAt")
    }
}
