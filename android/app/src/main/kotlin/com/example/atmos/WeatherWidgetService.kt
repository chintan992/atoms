package com.example.atmos

import android.app.IntentService
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.preference.PreferenceManager
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class WeatherWidgetService : IntentService("WeatherWidgetService") {

    companion object {
        const val TAG = "WeatherWidgetService"
        const val EXTRA_WIDGET_ID = "widget_id"
        const val CHANNEL_NAME = "com.example.atmos/weather_widget"
        const val METHOD_GET_WEATHER = "getWeatherForWidget"

        fun updateWeatherData(context: Context, widgetId: Int) {
            val intent = Intent(context, WeatherWidgetService::class.java).apply {
                putExtra(EXTRA_WIDGET_ID, widgetId)
            }
            context.startService(intent)
        }
    }

    override fun onHandleIntent(intent: Intent?) {
        intent?.let {
            val widgetId = it.getIntExtra(EXTRA_WIDGET_ID, -1)
            if (widgetId != -1) {
                updateWeatherForWidget(widgetId)
            }
        }
    }

    private fun getCurrentLocationCoordinates(): String? {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lat = prefs.getString("flutter.current_location_lat", null)
        val lon = prefs.getString("flutter.current_location_lon", null)
        
        return if (lat != null && lon != null) {
            "$lat,$lon"
        } else {
            null
        }
    }
    
    private fun updateWeatherForWidget(widgetId: Int) {
        Log.d(TAG, "Updating weather data for widget $widgetId")

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        var location = prefs.getString("widget_${widgetId}_location", null)

        Log.d(TAG, "Widget $widgetId location from prefs: $location")
        
        // If no location is configured, try to use current location as fallback
        if (location.isNullOrEmpty()) {
            Log.w(TAG, "No location configured for widget $widgetId, trying current location fallback")
            
            // Try to get current location coordinates from Flutter app
            val currentLocationCoords = getCurrentLocationCoordinates()
            if (currentLocationCoords != null) {
                location = currentLocationCoords
                Log.d(TAG, "Using current location fallback for widget $widgetId: $location")
                
                // Save this as the default location for this widget
                prefs.edit().putString("widget_${widgetId}_location", "CURRENT_LOCATION").apply()
            } else {
                // Final fallback to Calgary coordinates (user's detected location)
                location = "51.08,-113.98" // Calgary coordinates as fallback
                Log.d(TAG, "Using Calgary coordinates fallback for widget $widgetId: $location")
                prefs.edit().putString("widget_${widgetId}_location", location).apply()
            }
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
        // Handle special cases for current location or legacy "Current Location" string
        val actualLocation = if (location == "CURRENT_LOCATION") {
            getCurrentLocationCoordinates() ?: "51.08,-113.98" // Calgary coordinates as fallback
        } else if (location == "Current Location") {
            // Legacy case: fix this widget to use coordinates instead of literal "Current Location"
            val coords = getCurrentLocationCoordinates() ?: "51.08,-113.98"
            Log.w(TAG, "Widget $widgetId had legacy 'Current Location' string, fixing to coordinates: $coords")
            // Update the preference to store coordinates instead of the literal string
            prefs.edit().putString("widget_${widgetId}_location", coords).apply()
            coords
        } else {
            location
        }
                
                Log.d(TAG, "Fetching weather data for widget $widgetId with location: $actualLocation")
                val weatherData = WidgetWeatherService.getWeatherData(this@WeatherWidgetService, actualLocation)
                if (weatherData != null) {
                    saveWeatherData(widgetId, weatherData)
                    updateWidget(widgetId)
                    Log.d(TAG, "Successfully updated weather data for widget $widgetId")
                } else {
                    Log.w(TAG, "Failed to get weather data for widget $widgetId")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating weather for widget $widgetId", e)
            }
        }
    }

    private suspend fun getWeatherFromFlutter(location: String): WeatherInfo? {
        return withContext(Dispatchers.Main) {
            try {
                val flutterEngine = FlutterEngineCache.getInstance().get("atmos_engine")
                
                if (flutterEngine == null) {
                    Log.w(TAG, "Flutter engine not available, creating new engine")
                    // Create a new Flutter engine if not available
                    val newEngine = FlutterEngine(this@WeatherWidgetService)
                    FlutterEngineCache.getInstance().put("atmos_engine", newEngine)
                    
                    val channel = MethodChannel(
                        newEngine.dartExecutor.binaryMessenger,
                        CHANNEL_NAME
                    )
                    
                    return@withContext getWeatherDataFromChannel(channel, location)
                }

                val channel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    CHANNEL_NAME
                )
                
                return@withContext getWeatherDataFromChannel(channel, location)
            } catch (e: Exception) {
                Log.e(TAG, "Error communicating with Flutter", e)
                null
            }
        }
    }
    
    private suspend fun getWeatherDataFromChannel(channel: MethodChannel, location: String): WeatherInfo? {
        return suspendCancellableCoroutine { continuation ->
            channel.invokeMethod(
                METHOD_GET_WEATHER,
                JSONObject().apply {
                    put("location", location)
                }.toString(),
                object : MethodChannel.Result {
                    override fun success(resultData: Any?) {
                        if (resultData is String) {
                            try {
                                val jsonObject = JSONObject(resultData)
                                val weatherInfo = WeatherInfo(
                                    temperature = jsonObject.optString("temperature", "--°"),
                                    condition = jsonObject.optString("condition", "Unknown"),
                                    location = jsonObject.optString("location", location),
                                    lastUpdated = getCurrentTimeString(),
                                    iconResId = getWeatherIconResId(jsonObject.optString("icon", "")),
                                    highTemp = if (jsonObject.has("highTemp")) jsonObject.optString("highTemp", "--°") else "--°",
                                    lowTemp = if (jsonObject.has("lowTemp")) jsonObject.optString("lowTemp", "--°") else "--°",
                                    humidity = if (jsonObject.has("humidity")) jsonObject.optString("humidity", "--%") else "--%",
                                    windSpeed = if (jsonObject.has("windSpeed")) jsonObject.optString("windSpeed", "-- km/h") else "-- km/h",
                                    feelsLike = if (jsonObject.has("feelsLike")) jsonObject.optString("feelsLike", "--°") else "--°"
                                )
                                continuation.resume(weatherInfo, null)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error parsing weather result", e)
                                continuation.resume(null, null)
                            }
                        } else {
                            continuation.resume(null, null)
                        }
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        Log.e(TAG, "Error from Flutter channel: $errorCode - $errorMessage")
                        continuation.resume(null, null)
                    }

                    override fun notImplemented() {
                        Log.w(TAG, "Method $METHOD_GET_WEATHER not implemented in Flutter")
                        continuation.resume(null, null)
                    }
                }
            )
        }
    }

    private fun saveWeatherData(widgetId: Int, weatherInfo: WeatherInfo) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("widget_$widgetId", weatherInfo.toJson())
            .putLong("widget_${widgetId}_last_update", System.currentTimeMillis())
            .apply()

        Log.d(TAG, "Saved weather data for widget $widgetId")
    }

    private fun updateWidget(widgetId: Int) {
        val intent = Intent(this, WeatherWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
        }
        sendBroadcast(intent)
    }

    private fun getCurrentTimeString(): String {
        val showSeconds = WidgetUpdateSettings.shouldShowSeconds(this)
        val pattern = if (showSeconds) "h:mm:ss a" else "h:mm a"
        val sdf = SimpleDateFormat(pattern, Locale.getDefault())
        return sdf.format(Date())
    }

    private fun getWeatherIconResId(iconName: String): Int {
        return when (iconName) {
            "clear-day" -> R.drawable.ic_weather_sunny
            "clear-night" -> R.drawable.ic_weather_clear_night
            "partly-cloudy-day" -> R.drawable.ic_weather_partly_cloudy
            "partly-cloudy-night" -> R.drawable.ic_weather_partly_cloudy_night
            "cloudy" -> R.drawable.ic_weather_cloudy
            "rain" -> R.drawable.ic_weather_rain
            "snow" -> R.drawable.ic_weather_snow
            "thunderstorm" -> R.drawable.ic_weather_thunderstorm
            else -> R.drawable.ic_weather_default
        }
    }
}