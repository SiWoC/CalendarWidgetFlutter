package nl.siwoc.calendarwidget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.app.WallpaperManager
import java.io.ByteArrayOutputStream

/** Reads the device home-screen wallpaper for the in-app preview. */
object WallpaperReader {

    fun readHomeWallpaperPng(context: Context): ByteArray? {
        val drawable = WallpaperManager.getInstance(context)
            .getDrawable(WallpaperManager.FLAG_SYSTEM)
            ?: return null
        return drawableToPngBytes(drawable)
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = drawable.intrinsicWidth.coerceAtLeast(1)
            val height = drawable.intrinsicHeight.coerceAtLeast(1)
            Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { target ->
                val canvas = Canvas(target)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        }
        return ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }
}
