package nl.siwoc.calendarwidget

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
}
