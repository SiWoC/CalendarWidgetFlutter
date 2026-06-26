package nl.siwoc.calendarwidget

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.datastore.preferences.core.Preferences

private const val LOG_TAG = "CalendarWidget"

/** Home-screen widget: reads [CalendarWidgetData] snapshot and draws the calendar card. */
class CalendarWidget : GlanceAppWidget() {

    override val stateDefinition = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            CalendarWidgetContent(context)
        }
    }
}

@Composable
private fun CalendarWidgetContent(context: Context) {
    val glancePrefs = currentState<Preferences>()
    // Subscribes to [WidgetGlanceState.REDRAW_AT] so Glance recomposes after update().
    val redrawAt = glancePrefs[WidgetGlanceState.REDRAW_AT]
    val data = CalendarWidgetData.load(context)
    val settings = WidgetSettings.load(context)
    Log.d(
        LOG_TAG,
        "WidgetSettings.load (at draw): backgroundColor=${settings.backgroundColor} " +
            "backgroundOpacity=${settings.backgroundOpacity} redrawAt=$redrawAt",
    )
    val cardColor = ColorProvider(
        Utils.backgroundFill(settings.backgroundColor, settings.backgroundOpacity),
    )
    val openApp = actionStartActivity(
        Intent(context, MainActivity::class.java),
    )

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .clickable(onClick = openApp),
        contentAlignment = Alignment.TopCenter,
    ) {
        LazyColumn(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(cardColor)
                .cornerRadius(12.dp)
                .padding(horizontal = 10.dp, vertical = 10.dp),
        ) {
            when {
                data == null -> {
                    item {
                        PlaceholderText(
                            text = Utils.stringForLocale(
                                context,
                                settings.locale,
                                R.string.widget_empty_load_data,
                            ),
                            color = ColorProvider(Utils.hexToColor(settings.headerColor)),
                            fontSizeSp = settings.headerFontSize,
                        )
                    }
                }

                data.hasError -> {
                    item {
                        PlaceholderText(
                            text = data.error?.message.orEmpty(),
                            color = ColorProvider(Utils.hexToColor(data.headerColor)),
                            fontSizeSp = data.headerFontSize,
                        )
                    }
                }

                else -> {
                    val headerColor = ColorProvider(Utils.hexToColor(data.headerColor))
                    item {
                        Text(
                            text = data.headerDate,
                            modifier = GlanceModifier.fillMaxSize(),
                            style = TextStyle(
                                color = headerColor,
                                fontSize = data.headerFontSize.sp,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center,
                            ),
                        )
                    }
                    item {
                        Box(GlanceModifier.height(6.dp)) {}
                    }

                    for (section in data.sections) {
                        if (section.events.isEmpty()) continue
                        val sectionFontSize = section.events.first().fontSize
                        item {
                            Text(
                                text = section.title,
                                style = TextStyle(
                                    color = headerColor,
                                    fontSize = sectionFontSize.sp,
                                    fontWeight = FontWeight.Bold,
                                ),
                            )
                        }
                        items(section.events) { event ->
                            EventLine(event = event, headerColor = headerColor)
                        }
                        item {
                            Box(GlanceModifier.height(4.dp)) {}
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PlaceholderText(
    text: String,
    color: ColorProvider,
    fontSizeSp: Int,
) {
    Text(
        text = text,
        modifier = GlanceModifier.fillMaxSize(),
        style = TextStyle(
            color = color,
            fontSize = fontSizeSp.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        ),
    )
}

@Composable
private fun EventLine(event: CalendarEvent, headerColor: ColorProvider) {
    val eventColor = ColorProvider(Utils.hexToColor(event.color))
    val locationSuffix = event.location?.let { " [$it]" }.orEmpty()
    val prefix = if (event.isAllDay) {
        "● "
    } else {
        event.time?.let { "$it " }.orEmpty()
    }
    // Match Flutter preview: prefix keeps natural width; title uses remaining card
    // width and wraps (Expanded). fillMaxWidth + defaultWeight is Glance's equivalent.
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Vertical.Top,
    ) {
        Text(
            text = prefix,
            style = TextStyle(
                color = headerColor,
                fontSize = event.fontSize.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
        Text(
            text = "${event.title}$locationSuffix",
            modifier = GlanceModifier.defaultWeight(),
            style = TextStyle(
                color = eventColor,
                fontSize = event.fontSize.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
    }
}
