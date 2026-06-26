package nl.siwoc.calendarwidget

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Flutter ↔ Kotlin bridge for calendar refresh.
 *
 * [refresh] runs [CalendarRefreshWorker] off the main thread and returns snapshot JSON.
 */
class CalendarPlatformChannel(
    messenger: BinaryMessenger,
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, WidgetConstants.METHOD_CHANNEL)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_REFRESH -> refresh(result)
            METHOD_SCHEDULE_PERIODIC_REFRESH -> schedulePeriodicRefresh(result)
            METHOD_GET_WALLPAPER -> getWallpaper(result)
            METHOD_UPDATE_WIDGET -> updateWidget(result)
            else -> result.notImplemented()
        }
    }

    private fun schedulePeriodicRefresh(result: MethodChannel.Result) {
        try {
            CalendarRefreshScheduler.schedulePeriodicRefresh(context)
            result.success(null)
        } catch (exception: Exception) {
            result.error(
                ERROR_SCHEDULE_FAILED,
                exception.message,
                null,
            )
        }
    }

    private fun getWallpaper(result: MethodChannel.Result) {
        refreshExecutor.execute {
            try {
                val bytes = WallpaperReader.readHomeWallpaperPng(context)
                postResult(result) { it.success(bytes) }
            } catch (exception: Exception) {
                postResult(result) {
                    it.error(
                        ERROR_WALLPAPER_FAILED,
                        exception.message,
                        null,
                    )
                }
            }
        }
    }

    private fun updateWidget(result: MethodChannel.Result) {
        try {
            CalendarWidgetUpdater.requestUpdate(context)
            result.success(null)
        } catch (exception: Exception) {
            result.error(
                ERROR_UPDATE_WIDGET_FAILED,
                exception.message,
                null,
            )
        }
    }

    private fun refresh(result: MethodChannel.Result) {
        refreshExecutor.execute {
            try {
                val data = CalendarRefreshWorker.refresh(context)
                postResult(result) { it.success(data.toJsonString()) }
            } catch (exception: Exception) {
                postResult(result) {
                    it.error(
                        ERROR_REFRESH_FAILED,
                        exception.message,
                        null,
                    )
                }
            }
        }
    }

    private fun postResult(result: MethodChannel.Result, block: (MethodChannel.Result) -> Unit) {
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
        mainHandler.post { block(result) }
    }

    companion object {
        const val METHOD_REFRESH = "refresh"
        const val METHOD_SCHEDULE_PERIODIC_REFRESH = "schedulePeriodicRefresh"
        const val METHOD_GET_WALLPAPER = "getWallpaper"
        const val METHOD_UPDATE_WIDGET = "updateWidget"

        private const val ERROR_REFRESH_FAILED = "refresh_failed"
        private const val ERROR_SCHEDULE_FAILED = "schedule_failed"
        private const val ERROR_WALLPAPER_FAILED = "wallpaper_failed"
        private const val ERROR_UPDATE_WIDGET_FAILED = "update_widget_failed"

        private val refreshExecutor = Executors.newSingleThreadExecutor()
    }
}
