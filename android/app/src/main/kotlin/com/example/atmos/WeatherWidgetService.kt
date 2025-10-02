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

    private fun updateWeatherForWidget(widgetId: Int) {
        Log.d(TAG, "Updating weather data for widget $widgetId")

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val location = prefs.getString("widget_${widgetId}_location", null)

        if (location.isNullOrEmpty()) {
            Log.w(TAG, "No location configured for widget $widgetId")
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val weatherData = getWeatherFromFlutter(location)
                if (weatherData != null) {
                    saveWeatherData(widgetId, weatherData)
                    updateWidget(widgetId)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating weather for widget $widgetId", e)
            }
        }
    }

    private suspend fun getWeatherFromFlutter(location: String): WeatherInfo? {
        return withContext(Dispatchers.Main) {
            try {
                val flutterEngine = FlutterEngineCache.getInstance().get("atmos_engine")!!

                val channel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    CHANNEL_NAME
                )

                suspendCancellableCoroutine { continuation ->
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
                                            iconResId = getWeatherIconResId(jsonObject.optString("icon", ""))
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
            } catch (e: Exception) {
                Log.e(TAG, "Error communicating with Flutter", e)
                null
            }
        }
    }

    private fun saveWeatherData(widgetId: Int, weatherInfo: WeatherInfo) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("widget_$widgetId", weatherInfo.toJson())
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
        val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
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