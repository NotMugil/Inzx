package com.nirmal.inzx.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.nirmal.inzx.MainActivity
import com.nirmal.inzx.R

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

        const val ACTION_WIDGET_REFRESH = "com.nirmal.inzx.widget.REFRESH"
        const val ACTION_PREVIOUS = "com.nirmal.inzx.widget.PREVIOUS"
        const val ACTION_PLAY_PAUSE = "com.nirmal.inzx.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.nirmal.inzx.widget.NEXT"

        fun saveState(context: Context, args: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_TRACK_ID, args["trackId"] as? String)
                .putString(KEY_TITLE, args["title"] as? String ?: "Not playing")
                .putString(KEY_ARTIST, args["artist"] as? String ?: "Open Inzx to start music")
                .putBoolean(KEY_IS_PLAYING, args["isPlaying"] as? Boolean ?: false)
                .putBoolean(KEY_HAS_TRACK, args["hasTrack"] as? Boolean ?: false)
                .apply()
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

            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                setTextViewText(R.id.widget_track_title, title)
                setTextViewText(R.id.widget_track_artist, artist)
                setImageViewResource(
                    R.id.widget_btn_play_pause,
                    if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
                )

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
    }
}
