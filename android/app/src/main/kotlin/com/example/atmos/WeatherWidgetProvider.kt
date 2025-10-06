package com.example.atmos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.View
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        Log.d(TAG, "onAppWidgetOptionsChanged for widget $appWidgetId with options: $newOptions")
        updateAppWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "Updating widget $appWidgetId")

        // Determine widget size and select appropriate layout
        val widgetSize = getWidgetSize(appWidgetManager, appWidgetId)
        val layoutResId = getLayoutForSize(widgetSize)
        
        val views = RemoteViews(context.packageName, layoutResId)

        // Set theme-appropriate background
        val backgroundResId = getBackgroundForTheme(context)
        views.setInt(R.id.widget_root, "setBackgroundResource", backgroundResId)

        // Apply theme-aware text colors for better contrast
        applyThemeTextColors(context, views, widgetSize)

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
        updateWidgetDisplay(context, views, appWidgetId, widgetSize)

        // Apply size-specific UI adjustments (text sizes, labels, hide less important info)
        val (minWidthDp, minHeightDp) = getWidgetDimensions(appWidgetManager, appWidgetId)
        applySizeAdjustments(context, views, widgetSize, minWidthDp, minHeightDp)

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
        appWidgetId: Int,
        widgetSize: WidgetSize
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val widgetData = prefs.getString("widget_$appWidgetId", null)
        val lastUpdateTime = prefs.getLong("widget_${appWidgetId}_last_update", 0L)
        val currentTime = System.currentTimeMillis()
        val dataAge = currentTime - lastUpdateTime
        val maxAge = 30 * 60 * 1000L // 30 minutes

        // Use cached data if it's recent enough, otherwise show loading state
        if (widgetData != null && dataAge < maxAge) {
            try {
                Log.d(TAG, "Widget $appWidgetId using cached data (age: ${dataAge / 1000 / 60} minutes)")
                val weatherInfo = WeatherInfo.fromJson(widgetData)
                Log.d(TAG, "Widget $appWidgetId weather data: ${weatherInfo.temperature}, ${weatherInfo.condition}, ${weatherInfo.location}")

                views.setTextViewText(R.id.temperature_text, weatherInfo.temperature)
                views.setTextViewText(R.id.condition_text, weatherInfo.condition)
                views.setTextViewText(R.id.location_text, weatherInfo.location)
                views.setTextViewText(R.id.last_updated_text, weatherInfo.lastUpdated)

                // Set weather icon if available
                weatherInfo.iconResId?.let { iconResId ->
                    views.setImageViewResource(R.id.weather_icon, iconResId)
                }

                // Update additional weather details if available
                // Handle high temperature - show even if it's a fallback value
                if (weatherInfo.highTemp != null && weatherInfo.highTemp != "null") {
                    views.setTextViewText(R.id.high_temp_text, weatherInfo.highTemp)
                    views.setViewVisibility(R.id.high_temp_label, View.VISIBLE)
                    views.setViewVisibility(R.id.high_temp_text, View.VISIBLE)
                    
                    // Handle low temperature in context with high temperature
                    if (weatherInfo.lowTemp != null && weatherInfo.lowTemp != "null") {
                        // If both high and low are available and different from fallbacks
                        if (weatherInfo.highTemp != "--°" && weatherInfo.lowTemp != "--°") {
                            views.setTextViewText(R.id.high_temp_text, "${weatherInfo.highTemp}/${weatherInfo.lowTemp}")
                        } else if (weatherInfo.lowTemp != "--°") {
                            // If only low is meaningful, show that
                            views.setTextViewText(R.id.high_temp_text, weatherInfo.lowTemp)
                        }
                    }
                } else {
                    views.setViewVisibility(R.id.high_temp_label, View.GONE)
                    views.setViewVisibility(R.id.high_temp_text, View.GONE)
                }

                // Handle humidity - show even if it's a fallback value
                if (weatherInfo.humidity != null && weatherInfo.humidity != "null") {
                    views.setTextViewText(R.id.humidity_text, weatherInfo.humidity)
                    views.setViewVisibility(R.id.humidity_label, View.VISIBLE)
                    views.setViewVisibility(R.id.humidity_text, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.humidity_label, View.GONE)
                    views.setViewVisibility(R.id.humidity_text, View.GONE)
                }

                // Handle wind speed - show even if it's a fallback value
                if (weatherInfo.windSpeed != null && weatherInfo.windSpeed != "null") {
                    views.setTextViewText(R.id.wind_text, weatherInfo.windSpeed)
                    views.setViewVisibility(R.id.wind_label, View.VISIBLE)
                    views.setViewVisibility(R.id.wind_text, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.wind_label, View.GONE)
                    views.setViewVisibility(R.id.wind_text, View.GONE)
                }

                // Handle feels like temperature (only for large widget)
                if (widgetSize == WidgetSize.LARGE) {
                    if (weatherInfo.feelsLike != null && weatherInfo.feelsLike != "null") {
                        views.setTextViewText(R.id.feels_like_text, weatherInfo.feelsLike)
                        views.setViewVisibility(R.id.feels_like_label, View.VISIBLE)
                        views.setViewVisibility(R.id.feels_like_text, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.feels_like_label, View.GONE)
                        views.setViewVisibility(R.id.feels_like_text, View.GONE)
                    }
                }

                Log.d(TAG, "Updated widget $appWidgetId with weather data (age: ${dataAge / 1000 / 60} minutes)")
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing widget data for $appWidgetId", e)
                setDefaultWidgetState(views, widgetSize)
            }
        } else {
            // Show loading state for stale or missing data
            if (widgetData != null) {
                Log.d(TAG, "Widget $appWidgetId data is stale (age: ${dataAge / 1000 / 60} minutes), showing loading state")
            } else {
                Log.d(TAG, "No cached data for widget $appWidgetId, showing loading state")
            }
            setDefaultWidgetState(views, widgetSize)
        }
    }

    private fun setDefaultWidgetState(views: RemoteViews, widgetSize: WidgetSize) {
        views.setTextViewText(R.id.temperature_text, "--°")
        views.setTextViewText(R.id.condition_text, "Loading...")
        views.setTextViewText(R.id.location_text, "No location")
        views.setImageViewResource(R.id.weather_icon, R.drawable.ic_weather_default)
        
        // Set default values based on widget size
        when (widgetSize) {
            WidgetSize.SMALL -> {
                // Small widget only shows basic info
            }
            WidgetSize.MEDIUM -> {
                views.setTextViewText(R.id.last_updated_text, "")
                views.setTextViewText(R.id.high_temp_text, "--°")
                views.setTextViewText(R.id.humidity_text, "--%")
                views.setTextViewText(R.id.wind_text, "-- km/h")
                views.setViewVisibility(R.id.high_temp_label, View.VISIBLE)
                views.setViewVisibility(R.id.high_temp_text, View.VISIBLE)
                views.setViewVisibility(R.id.humidity_label, View.VISIBLE)
                views.setViewVisibility(R.id.humidity_text, View.VISIBLE)
                views.setViewVisibility(R.id.wind_label, View.VISIBLE)
                views.setViewVisibility(R.id.wind_text, View.VISIBLE)
            }
            WidgetSize.LARGE -> {
                views.setTextViewText(R.id.last_updated_text, "")
                views.setTextViewText(R.id.high_temp_text, "--° / --°")
                views.setTextViewText(R.id.humidity_text, "--%")
                views.setTextViewText(R.id.wind_text, "-- km/h")
                views.setTextViewText(R.id.feels_like_text, "--°")
                views.setViewVisibility(R.id.high_temp_label, View.VISIBLE)
                views.setViewVisibility(R.id.high_temp_text, View.VISIBLE)
                views.setViewVisibility(R.id.humidity_label, View.VISIBLE)
                views.setViewVisibility(R.id.humidity_text, View.VISIBLE)
                views.setViewVisibility(R.id.wind_label, View.VISIBLE)
                views.setViewVisibility(R.id.wind_text, View.VISIBLE)
                views.setViewVisibility(R.id.feels_like_label, View.VISIBLE)
                views.setViewVisibility(R.id.feels_like_text, View.VISIBLE)
            }
        }
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

    private enum class WidgetSize {
        SMALL, MEDIUM, LARGE
    }

    private fun getWidgetSize(appWidgetManager: AppWidgetManager, appWidgetId: Int): WidgetSize {
        val (minWidth, minHeight) = getWidgetDimensions(appWidgetManager, appWidgetId)
        // Treat very short heights (1 row tall) as SMALL regardless of width
        return when {
            minHeight <= 70 -> WidgetSize.SMALL // 3x1, 2x1, 4x1
            minWidth <= 110 -> WidgetSize.SMALL // 1x2, 1x3, 1x4 narrow
            minHeight <= 110 -> WidgetSize.MEDIUM // 3x2, 4x2 wide but short
            else -> WidgetSize.LARGE
        }
    }

    private fun getWidgetDimensions(appWidgetManager: AppWidgetManager, appWidgetId: Int): Pair<Int, Int> {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        return Pair(minWidth, minHeight)
    }

    private fun getLayoutForSize(widgetSize: WidgetSize): Int {
        return when (widgetSize) {
            WidgetSize.SMALL -> R.layout.weather_widget_small
            WidgetSize.MEDIUM -> R.layout.weather_widget_medium
            WidgetSize.LARGE -> R.layout.weather_widget_large
        }
    }

    private fun getBackgroundForTheme(context: Context): Int {
        return if (isDarkMode(context)) R.drawable.widget_background_dark else R.drawable.widget_background_light
    }

    private fun isDarkMode(context: Context): Boolean {
        return when (WidgetUpdateSettings.getThemeMode(context)) {
            WidgetUpdateSettings.THEME_DARK -> true
            WidgetUpdateSettings.THEME_LIGHT -> false
            WidgetUpdateSettings.THEME_AUTO -> {
                val nightModeFlags = context.resources.configuration.uiMode and
                        android.content.res.Configuration.UI_MODE_NIGHT_MASK
                nightModeFlags == android.content.res.Configuration.UI_MODE_NIGHT_YES
            }
            else -> false
        }
    }

    private fun applyThemeTextColors(context: Context, views: RemoteViews, widgetSize: WidgetSize) {
        val dark = isDarkMode(context)
        // Primary text: strong contrast
        val primary = if (dark) 0xFFFFFFFF.toInt() else 0xFF111111.toInt()
        // Secondary text: slightly dimmed but still accessible
        val secondary = if (dark) 0xCCFFFFFF.toInt() else 0xFF444444.toInt()

        when (widgetSize) {
            WidgetSize.SMALL -> {
                views.setTextColor(R.id.temperature_text, primary)
                views.setTextColor(R.id.condition_text, secondary)
                views.setTextColor(R.id.location_text, secondary)
            }
            WidgetSize.MEDIUM -> {
                views.setTextColor(R.id.location_text, primary)
                views.setTextColor(R.id.last_updated_text, secondary)
                views.setTextColor(R.id.temperature_text, primary)
                views.setTextColor(R.id.condition_text, secondary)
                views.setTextColor(R.id.high_temp_label, secondary)
                views.setTextColor(R.id.high_temp_text, primary)
                views.setTextColor(R.id.humidity_label, secondary)
                views.setTextColor(R.id.humidity_text, primary)
                views.setTextColor(R.id.wind_label, secondary)
                views.setTextColor(R.id.wind_text, primary)
            }
            WidgetSize.LARGE -> {
                views.setTextColor(R.id.location_text, primary)
                views.setTextColor(R.id.last_updated_text, secondary)
                views.setTextColor(R.id.temperature_text, primary)
                views.setTextColor(R.id.condition_text, secondary)
                views.setTextColor(R.id.high_temp_label, secondary)
                views.setTextColor(R.id.high_temp_text, primary)
                views.setTextColor(R.id.humidity_label, secondary)
                views.setTextColor(R.id.humidity_text, primary)
                views.setTextColor(R.id.wind_label, secondary)
                views.setTextColor(R.id.wind_text, primary)
                views.setTextColor(R.id.feels_like_label, secondary)
                views.setTextColor(R.id.feels_like_text, primary)
            }
        }
    }

    private fun applySizeAdjustments(
        context: Context,
        views: RemoteViews,
        widgetSize: WidgetSize,
        minWidthDp: Int,
        minHeightDp: Int
    ) {
        when (widgetSize) {
            WidgetSize.SMALL -> {
                // For 1x2, 1x3, 1x4, 2x1, 3x1, 4x1: compact text sizes
                val isOneRow = minHeightDp <= 70
                // Tight height: favor one prominent line (temp) and minimal secondary
                if (isOneRow) {
                    views.setTextViewTextSize(R.id.temperature_text, TypedValue.COMPLEX_UNIT_SP, 15f)
                    views.setTextViewTextSize(R.id.condition_text, TypedValue.COMPLEX_UNIT_SP, 9f)
                    views.setTextViewTextSize(R.id.location_text, TypedValue.COMPLEX_UNIT_SP, 9f)
                    // Hide condition if width is extremely tight to avoid clipping
                    if (minWidthDp <= 120) {
                        views.setViewVisibility(R.id.condition_text, View.GONE)
                    } else {
                        views.setViewVisibility(R.id.condition_text, View.VISIBLE)
                    }
                } else {
                    views.setTextViewTextSize(R.id.temperature_text, TypedValue.COMPLEX_UNIT_SP, 16f)
                    views.setTextViewTextSize(R.id.condition_text, TypedValue.COMPLEX_UNIT_SP, 10f)
                    views.setTextViewTextSize(R.id.location_text, TypedValue.COMPLEX_UNIT_SP, 9f)
                    views.setViewVisibility(R.id.condition_text, View.VISIBLE)
                }
                // Location visibility based on width
                if (minWidthDp <= 90) {
                    views.setViewVisibility(R.id.location_text, View.GONE)
                } else {
                    views.setViewVisibility(R.id.location_text, View.VISIBLE)
                }
            }
            WidgetSize.MEDIUM -> {
                // For 3x2, 4x2: slightly smaller text if width is tight, abbreviate labels, hide last updated if needed
                if (minWidthDp <= 180) {
                    views.setTextViewTextSize(R.id.temperature_text, TypedValue.COMPLEX_UNIT_SP, 20f)
                    views.setTextViewTextSize(R.id.condition_text, TypedValue.COMPLEX_UNIT_SP, 11f)
                    views.setTextViewText(R.id.high_temp_label, "H/L")
                    views.setTextViewText(R.id.humidity_label, "Hum")
                    views.setTextViewText(R.id.wind_label, "Wind")
                    views.setViewVisibility(R.id.last_updated_text, View.GONE)
                } else {
                    views.setViewVisibility(R.id.last_updated_text, View.VISIBLE)
                }
            }
            WidgetSize.LARGE -> {
                // Leave as-is; large layout already fits well
            }
        }
    }
}