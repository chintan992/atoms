package com.example.atmos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import androidx.preference.PreferenceManager
import androidx.work.WorkManager
import com.example.atmos.WeatherWidgetService.Companion.EXTRA_WIDGET_ID
import com.example.atmos.WeatherWidgetService.Companion.updateWeatherData
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class WeatherWidgetProvider : AppWidgetProvider() {

    companion object {
        const val TAG = "WeatherWidgetProvider"
        const val ACTION_UPDATE_WEATHER = "com.example.atmos.action.UPDATE_WEATHER"
        const val UPDATE_INTERVAL = 30 * 60 * 1000L // 30 minutes (kept for backward compatibility)
        const val MIN_UPDATE_INTERVAL = 30L // minutes
        const val MAX_UPDATE_INTERVAL = 60L // minutes
        const val DEFAULT_UPDATE_INTERVAL = 30L // minutes
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for widgets: ${appWidgetIds.joinToString()}")

        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "onEnabled called")
        super.onEnabled(context)
        scheduleNextUpdate(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "onDisabled called")
        super.onDisabled(context)
        cancelUpdates(context)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        Log.d(TAG, "onDeleted called for widgets: ${appWidgetIds.joinToString()}")
        super.onDeleted(context, appWidgetIds)

        // Clean up preferences for deleted widgets
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        for (appWidgetId in appWidgetIds) {
            prefs.edit().remove("widget_$appWidgetId").apply()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")

        when (intent.action) {
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                if (appWidgetIds != null) {
                    onUpdate(context, AppWidgetManager.getInstance(context), appWidgetIds)
                }
            }
        }

        super.onReceive(context, intent)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "Updating widget $appWidgetId")

        val views = RemoteViews(context.packageName, R.layout.weather_widget)

        // Set click intent to open main app
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // Update widget with current data
        updateWidgetDisplay(context, views, appWidgetId)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)

        // Trigger background update for fresh data
        CoroutineScope(Dispatchers.IO).launch {
            try {
                updateWeatherData(context, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating weather data for widget $appWidgetId", e)
            }
        }
    }

    private fun updateWidgetDisplay(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val widgetData = prefs.getString("widget_$appWidgetId", null)

        if (widgetData != null) {
            try {
                val weatherInfo = WeatherInfo.fromJson(widgetData)

                views.setTextViewText(R.id.temperature_text, weatherInfo.temperature)
                views.setTextViewText(R.id.condition_text, weatherInfo.condition)
                views.setTextViewText(R.id.location_text, weatherInfo.location)
                views.setTextViewText(R.id.last_updated_text, weatherInfo.lastUpdated)

                // Set weather icon if available
                weatherInfo.iconResId?.let { iconResId ->
                    views.setImageViewResource(R.id.weather_icon, iconResId)
                }

                Log.d(TAG, "Updated widget $appWidgetId with weather data")
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing widget data for $appWidgetId", e)
                setDefaultWidgetState(views)
            }
        } else {
            setDefaultWidgetState(views)
        }
    }

    private fun setDefaultWidgetState(views: RemoteViews) {
        views.setTextViewText(R.id.temperature_text, "--°")
        views.setTextViewText(R.id.condition_text, "Loading...")
        views.setTextViewText(R.id.location_text, "No location")
        views.setTextViewText(R.id.last_updated_text, "")
        views.setImageViewResource(R.id.weather_icon, R.drawable.ic_weather_default)
    }

    private fun scheduleNextUpdate(context: Context) {
        // Schedule periodic work using WorkManager with user-configured interval
        WeatherUpdateWorker.schedulePeriodicWork(context)

        // Also schedule an immediate update for better user experience
        WeatherUpdateWorker.scheduleOneTimeWork(context, 1) // Update in 1 minute

        val interval = WidgetUpdateSettings.getUpdateIntervalMinutes(context)
        Log.d(TAG, "Scheduled WorkManager updates every $interval minutes")
    }

    private fun cancelUpdates(context: Context) {
        // Cancel WorkManager periodic work
        WeatherUpdateWorker.cancelPeriodicWork(context)

        Log.d(TAG, "Cancelled WorkManager scheduled updates")
    }
}