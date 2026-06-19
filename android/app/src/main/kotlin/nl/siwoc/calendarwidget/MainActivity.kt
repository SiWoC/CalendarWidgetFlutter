package nl.siwoc.calendarwidget

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var calendarPlatformChannel: CalendarPlatformChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        calendarPlatformChannel = CalendarPlatformChannel(
            messenger = flutterEngine.dartExecutor.binaryMessenger,
            context = applicationContext,
        )
    }
}
