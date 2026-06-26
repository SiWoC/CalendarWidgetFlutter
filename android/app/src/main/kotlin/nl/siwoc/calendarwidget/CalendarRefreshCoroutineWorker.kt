package nl.siwoc.calendarwidget

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * WorkManager entry point for background refresh.
 * Delegates to [CalendarRefreshWorker.refresh] — same path as MethodChannel.
 */
class CalendarRefreshCoroutineWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        return try {
            CalendarRefreshWorker.refresh(applicationContext)
            Result.success()
        } catch (exception: Exception) {
            Result.failure()
        }
    }
}
