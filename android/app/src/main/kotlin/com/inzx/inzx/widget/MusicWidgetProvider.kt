package com.nirmal.inzx.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.nirmal.inzx.MainActivity
import com.nirmal.inzx.R
import java.io.File
import java.io.FileOutputStream
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class MusicWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_WIDGET_REFRESH) {
            updateAllWidgets(context)
        }
    }

    companion object {
        private const val PREFS_NAME = "music_widget_prefs"
        private const val KEY_TRACK_ID = "track_id"
        private const val KEY_TITLE = "title"
        private const val KEY_ARTIST = "artist"
        private const val KEY_IS_PLAYING = "is_playing"
        private const val KEY_HAS_TRACK = "has_track"
        private const val KEY_POSITION_MS = "position_ms"
        private const val KEY_DURATION_MS = "duration_ms"
        private const val KEY_ARTWORK_PATH = "artwork_path"
        private const val KEY_ACCENT_COLOR = "accent_color"
        private const val DEFAULT_WIDGET_BG = "#E6121212"

        const val ACTION_WIDGET_REFRESH = "com.nirmal.inzx.widget.REFRESH"
        const val ACTION_PREVIOUS = "com.nirmal.inzx.widget.PREVIOUS"
        const val ACTION_PLAY_PAUSE = "com.nirmal.inzx.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.nirmal.inzx.widget.NEXT"

        fun saveState(context: Context, args: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()
            val previousTrackId = prefs.getString(KEY_TRACK_ID, null)
            val previousArtworkPath = prefs.getString(KEY_ARTWORK_PATH, null)
            val incomingTrackId = args["trackId"] as? String
            val hasTrackKey = args.containsKey("trackId")
            val trackChanged = hasTrackKey && incomingTrackId != previousTrackId

            if (trackChanged) {
                deleteArtworkFile(previousArtworkPath)
                editor.remove(KEY_ARTWORK_PATH)
                editor.remove(KEY_ACCENT_COLOR)
            }

            if (args.containsKey("trackId")) {
                editor.putString(KEY_TRACK_ID, args["trackId"] as? String)
            }
            if (args.containsKey("title")) {
                editor.putString(KEY_TITLE, args["title"] as? String ?: "Not playing")
            }
            if (args.containsKey("artist")) {
                editor.putString(KEY_ARTIST, args["artist"] as? String ?: "Open Inzx to start music")
            }
            if (args.containsKey("isPlaying")) {
                editor.putBoolean(KEY_IS_PLAYING, args["isPlaying"] as? Boolean ?: false)
            }
            if (args.containsKey("hasTrack")) {
                editor.putBoolean(KEY_HAS_TRACK, args["hasTrack"] as? Boolean ?: false)
            }
            if (args.containsKey("positionMs")) {
                val positionMs = (args["positionMs"] as? Number)?.toLong() ?: 0L
                editor.putLong(KEY_POSITION_MS, positionMs)
            }
            if (args.containsKey("durationMs")) {
                val durationMs = (args["durationMs"] as? Number)?.toLong() ?: 0L
                editor.putLong(KEY_DURATION_MS, durationMs)
            }
            if (args.containsKey("artBytes")) {
                val artBytes = args["artBytes"] as? ByteArray
                if (artBytes != null && artBytes.isNotEmpty()) {
                    val trackIdForArt = incomingTrackId ?: previousTrackId ?: "current"
                    val artwork = saveArtworkToCache(context, trackIdForArt, artBytes)
                    if (artwork != null) {
                        editor.putString(KEY_ARTWORK_PATH, artwork.path)
                        editor.putInt(KEY_ACCENT_COLOR, artwork.accentColor)
                    }
                }
            }

            editor.apply()
        }

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, MusicWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { appWidgetId ->
                updateWidget(context, manager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString(KEY_TITLE, "Not playing") ?: "Not playing"
            val artist = prefs.getString(KEY_ARTIST, "Open Inzx to start music") ?: "Open Inzx to start music"
            val isPlaying = prefs.getBoolean(KEY_IS_PLAYING, false)
            val hasTrack = prefs.getBoolean(KEY_HAS_TRACK, false)
            val positionMs = prefs.getLong(KEY_POSITION_MS, 0L)
            val durationMs = prefs.getLong(KEY_DURATION_MS, 0L)
            val artworkPath = prefs.getString(KEY_ARTWORK_PATH, null)
            val accentColor = prefs.getInt(KEY_ACCENT_COLOR, Color.WHITE)
            val hasProgress = hasTrack && durationMs > 0L
            val progress = if (hasProgress) {
                ((positionMs.coerceIn(0L, durationMs) * 1000L) / durationMs).toInt()
            } else {
                0
            }
            val iconColor = if (hasTrack) accentColor else Color.parseColor("#DDFFFFFF")
            val titleColor = if (hasTrack) blendColors(accentColor, Color.WHITE, 0.35f) else Color.WHITE
            val widgetBackgroundColor = if (hasTrack) {
                withAlpha(blendColors(accentColor, Color.BLACK, 0.78f), 220)
            } else {
                Color.parseColor(DEFAULT_WIDGET_BG)
            }

            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                setTextViewText(R.id.widget_track_title, title)
                setTextViewText(R.id.widget_track_artist, artist)
                setTextColor(R.id.widget_track_title, titleColor)
                setTextColor(R.id.widget_track_artist, withAlpha(Color.WHITE, 204))
                setInt(R.id.widget_bg_tint, "setBackgroundColor", widgetBackgroundColor)

                val launchIntent = Intent(context, MainActivity::class.java)
                val launchPendingIntent = PendingIntent.getActivity(
                    context,
                    100,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, launchPendingIntent)

                setOnClickPendingIntent(
                    R.id.widget_btn_previous,
                    actionPendingIntent(context, ACTION_PREVIOUS, 101)
                )
                setOnClickPendingIntent(
                    R.id.widget_btn_play_pause,
                    actionPendingIntent(context, ACTION_PLAY_PAUSE, 102)
                )
                setOnClickPendingIntent(
                    R.id.widget_btn_next,
                    actionPendingIntent(context, ACTION_NEXT, 103)
                )

                setBoolean(R.id.widget_btn_previous, "setEnabled", hasTrack)
                setBoolean(R.id.widget_btn_play_pause, "setEnabled", hasTrack)
                setBoolean(R.id.widget_btn_next, "setEnabled", hasTrack)

                setProgressBar(R.id.widget_progress, 1000, progress, false)
                setViewVisibility(
                    R.id.widget_progress,
                    if (hasProgress) android.view.View.VISIBLE else android.view.View.GONE
                )
            }

            setTintedControlIcons(
                context = context,
                views = views,
                isPlaying = isPlaying,
                iconColor = iconColor
            )

            val artwork = loadArtwork(artworkPath)
            if (artwork != null) {
                views.setImageViewBitmap(R.id.widget_artwork, artwork)
            } else {
                views.setImageViewResource(R.id.widget_artwork, R.drawable.ic_notification)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun actionPendingIntent(
            context: Context,
            action: String,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(context, MusicWidgetActionReceiver::class.java).apply {
                this.action = action
            }
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private data class ArtworkCacheResult(
            val path: String,
            val accentColor: Int
        )

        private fun saveArtworkToCache(
            context: Context,
            trackId: String,
            bytes: ByteArray
        ): ArtworkCacheResult? {
            return try {
                val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
                val scaled = Bitmap.createScaledBitmap(decoded, 128, 128, true)
                val accentColor = extractAccentColor(scaled)
                val dir = File(context.cacheDir, "widget_art")
                if (!dir.exists()) dir.mkdirs()

                val safeTrackId = trackId.replace(Regex("[^A-Za-z0-9._-]"), "_")
                val file = File(dir, "$safeTrackId.jpg")
                FileOutputStream(file).use { stream ->
                    scaled.compress(Bitmap.CompressFormat.JPEG, 90, stream)
                    stream.flush()
                }

                if (scaled != decoded) {
                    decoded.recycle()
                }
                scaled.recycle()
                ArtworkCacheResult(file.absolutePath, accentColor)
            } catch (_: Exception) {
                null
            }
        }

        private fun loadArtwork(path: String?): Bitmap? {
            if (path.isNullOrEmpty()) return null
            return try {
                val file = File(path)
                if (!file.exists()) return null
                BitmapFactory.decodeFile(file.absolutePath)
            } catch (_: Exception) {
                null
            }
        }

        private fun deleteArtworkFile(path: String?) {
            if (path.isNullOrEmpty()) return
            try {
                File(path).delete()
            } catch (_: Exception) {
                // Ignore cleanup errors
            }
        }

        private fun extractAccentColor(bitmap: Bitmap): Int {
            val sample = Bitmap.createScaledBitmap(bitmap, 24, 24, true)
            var bestScore = -1f
            var bestColor = Color.WHITE
            val hsv = FloatArray(3)

            for (x in 0 until sample.width) {
                for (y in 0 until sample.height) {
                    val pixel = sample.getPixel(x, y)
                    if (Color.alpha(pixel) < 180) continue
                    Color.colorToHSV(pixel, hsv)
                    val saturation = hsv[1]
                    val value = hsv[2]
                    val valueScore = 1f - abs(value - 0.65f)
                    val score = saturation * 0.72f + valueScore * 0.28f
                    if (score > bestScore) {
                        val boostedSaturation = max(0.45f, saturation)
                        val normalizedValue = min(0.90f, max(0.55f, value))
                        bestColor = Color.HSVToColor(
                            floatArrayOf(hsv[0], boostedSaturation, normalizedValue)
                        )
                        bestScore = score
                    }
                }
            }

            sample.recycle()
            return bestColor
        }

        private fun withAlpha(color: Int, alpha: Int): Int {
            val clampedAlpha = alpha.coerceIn(0, 255)
            return Color.argb(
                clampedAlpha,
                Color.red(color),
                Color.green(color),
                Color.blue(color)
            )
        }

        private fun blendColors(color1: Int, color2: Int, ratio: Float): Int {
            val clamped = ratio.coerceIn(0f, 1f)
            val inverse = 1f - clamped
            val r = (Color.red(color1) * inverse + Color.red(color2) * clamped).toInt()
            val g = (Color.green(color1) * inverse + Color.green(color2) * clamped).toInt()
            val b = (Color.blue(color1) * inverse + Color.blue(color2) * clamped).toInt()
            return Color.rgb(r, g, b)
        }

        private fun setTintedControlIcons(
            context: Context,
            views: RemoteViews,
            isPlaying: Boolean,
            iconColor: Int
        ) {
            val prev = tintedSystemIconBitmap(context, android.R.drawable.ic_media_previous, iconColor)
            val playPause = tintedSystemIconBitmap(
                context,
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                iconColor
            )
            val next = tintedSystemIconBitmap(context, android.R.drawable.ic_media_next, iconColor)

            if (prev != null) views.setImageViewBitmap(R.id.widget_btn_previous, prev)
            if (playPause != null) views.setImageViewBitmap(R.id.widget_btn_play_pause, playPause)
            if (next != null) views.setImageViewBitmap(R.id.widget_btn_next, next)
        }

        private fun tintedSystemIconBitmap(
            context: Context,
            resId: Int,
            color: Int
        ): Bitmap? {
            return try {
                val drawable = ContextCompat.getDrawable(context, resId)?.mutate() ?: return null
                drawable.setTint(color)

                val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 64
                val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 64
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            } catch (_: Exception) {
                null
            }
        }
    }
}
