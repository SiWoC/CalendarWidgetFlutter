package nl.siwoc.calendarwidget

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color as AndroidColor
import androidx.annotation.StringRes
import androidx.compose.ui.graphics.Color
import java.util.Locale

object Utils {
    fun hexToArgb(hex: String): Int {
        val normalized = when {
            hex.startsWith("#") -> hex
            hex.startsWith("0x", ignoreCase = true) -> "#${hex.substring(2)}"
            else -> "#$hex"
        }
        return AndroidColor.parseColor(normalized)
    }

    fun argbToHex(argb: Int): String = "#%08X".format(argb)
    
    fun hexToColor(hex: String): Color = Color(hexToArgb(hex))

    fun backgroundFill(hex: String, opacityPercent: Int): Color {
        val clamped = opacityPercent.coerceIn(0, 100)
        return hexToColor(hex).copy(alpha = clamped / 100f)
    }

    /** Resolves [resId] for the user-selected app locale ([WidgetSettings.locale]). */
    fun stringForLocale(context: Context, localeTag: String, @StringRes resId: Int): String {
        val locale = Locale.forLanguageTag(localeTag)
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        return context.createConfigurationContext(config).getString(resId)
    }
}

/** Flutter [shared_preferences] may store ints as [Long] on Android. */
fun SharedPreferences.getIntCompat(key: String, defaultValue: Int): Int {
    val raw = all[key] ?: return defaultValue
    return when (raw) {
        is Int -> raw
        is Long -> raw.toInt()
        is String -> raw.toIntOrNull() ?: defaultValue
        else -> defaultValue
    }
}
