package nl.siwoc.calendarwidget

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/** Registers and updates the periodic WorkManager refresh job. */
object CalendarRefreshScheduler {

    fun schedulePeriodicRefresh(context: Context) {
        val request = PeriodicWorkRequestBuilder<CalendarRefreshCoroutineWorker>(
            WidgetConstants.PERIODIC_REFRESH_INTERVAL_MINUTES,
            TimeUnit.MINUTES,
        ).build()

        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            WidgetConstants.PERIODIC_REFRESH_WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }
}
