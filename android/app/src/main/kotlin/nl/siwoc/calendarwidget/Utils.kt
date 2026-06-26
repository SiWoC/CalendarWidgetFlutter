package nl.siwoc.calendarwidget

import android.content.SharedPreferences
import android.graphics.Color as AndroidColor
import androidx.compose.ui.graphics.Color

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
