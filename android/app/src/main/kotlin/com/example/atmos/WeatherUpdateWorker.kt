package com.example.atmos

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.work.*
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

class WeatherUpdateWorker(private val context: Context, workerParams: WorkerParameters) : CoroutineWorker(context, workerParams) {

    companion object {
        const val TAG = "WeatherUpdateWorker"
        const val CHANNEL_NAME = "com.example.atmos/weather_widget"
        const val METHOD_GET_WEATHER = "getWeatherForWidget"
        const val WORK_NAME = "weather_update_work"
        const val MIN_UPDATE_INTERVAL = 30L // minutes
        const val MAX_UPDATE_INTERVAL = 60L // minutes
        const val DEFAULT_UPDATE_INTERVAL = 30L // minutes

        fun schedulePeriodicWork(context: Context, updateIntervalMinutes: Long? = null) {
            val interval = updateIntervalMinutes ?: WidgetUpdateSettings.getUpdateIntervalMinutes(context)
            Log.d(TAG, "Scheduling periodic work with interval: $interval minutes")

            val constraints = createWorkConstraints(context)

            val workRequest = PeriodicWorkRequestBuilder<WeatherUpdateWorker>(
                interval, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                            .setBackoffCriteria(
                                BackoffPolicy.EXPONENTIAL,
                                WorkRequest.MIN_BACKOFF_MILLIS,
                                TimeUnit.MILLISECONDS
                            )
                            .addTag(WORK_NAME)
                            .build()
                
                        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                            WORK_NAME,
                            ExistingPeriodicWorkPolicy.REPLACE,
                            workRequest
                        )
                
                        Log.d(TAG, "Scheduled periodic weather updates every $interval minutes")
        }
                
                    fun cancelPeriodicWork(context: Context) {
                        Log.d(TAG, "Cancelling periodic work")
                        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }

        private fun createWorkConstraints(context: Context): Constraints {
            val builder = Constraints.Builder()

            // Network constraints based on user preferences
            if (WidgetUpdateSettings.isWifiOnlyEnabled(context)) {
                builder.setRequiredNetworkType(NetworkType.UNMETERED) // WiFi only
            } else {
                builder.setRequiredNetworkType(NetworkType.CONNECTED) // Any network
            }

            // Battery optimization constraints
            if (WidgetUpdateSettings.isBatteryOptimizationEnabled(context)) {
                builder
                    .setRequiresBatteryNotLow(true) // Don't run if battery is low
                    .setRequiresDeviceIdle(false) // Can run while device is active but prefer idle
            }

            return builder.build()
        }

        fun scheduleOneTimeWork(context: Context, delayMinutes: Long = 5) {
            Log.d(TAG, "Scheduling one-time work with delay: $delayMinutes minutes")

            val constraints = createWorkConstraints(context)

            val workRequest = OneTimeWorkRequestBuilder<WeatherUpdateWorker>()
                .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .addTag("${WORK_NAME}_onetime")
                .build()

            WorkManager.getInstance(context).enqueue(workRequest)
        }
    }

    override suspend fun doWork(): Result {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting weather update work - attempt ${runAttemptCount}")

                // Check if we've exceeded max retries
                val maxRetries = WidgetUpdateSettings.getMaxRetries(applicationContext)
                if (runAttemptCount > maxRetries) {
                    Log.w(TAG, "Exceeded maximum retry attempts ($maxRetries)")
                    return@withContext Result.failure()
                }

                // Get all widget IDs that need updating
                val widgetIds = getActiveWidgetIds()

                if (widgetIds.isEmpty()) {
                    Log.d(TAG, "No active widgets found")
                    return@withContext Result.success()
                }

                Log.d(TAG, "Updating ${widgetIds.size} widgets: ${widgetIds.joinToString()}")

                // Update each widget with individual error handling
                val results = mutableListOf<Boolean>()
                for (widgetId in widgetIds) {
                    val result = updateWidgetWeather(widgetId)
                    results.add(result)
                }

                val successCount = results.count { it }
                val failureCount = results.size - successCount

                Log.d(TAG, "Successfully updated $successCount/${widgetIds.size} widgets ($failureCount failed)")

                // Determine result based on success rate and retry policy
                when {
                    successCount == widgetIds.size -> {
                        // All updates successful
                        Log.d(TAG, "All widgets updated successfully")
                        Result.success()
                    }
                    successCount > 0 -> {
                        // Partial success - some widgets updated
                        Log.i(TAG, "Partial success: $successCount/${widgetIds.size} widgets updated")
                        // Retry with exponential backoff for remaining failures
                        Result.retry()
                    }
                    runAttemptCount < maxRetries -> {
                        // Complete failure but still have retry attempts
                        Log.w(TAG, "All widgets failed to update, retrying (attempt ${runAttemptCount}/$maxRetries)")
                        Result.retry()
                    }
                    else -> {
                        // Complete failure and no more retries
                        Log.e(TAG, "All widgets failed to update after $maxRetries attempts")
                        Result.failure()
                    }
                }

            } catch (e: Exception) {
                Log.e(TAG, "Weather update work failed with exception", e)

                // Retry for unexpected exceptions if we haven't exceeded max attempts
                val maxRetries = WidgetUpdateSettings.getMaxRetries(applicationContext)
                if (runAttemptCount < maxRetries) {
                    Log.d(TAG, "Retrying after exception (attempt ${runAttemptCount}/$maxRetries)")
                    Result.retry()
                } else {
                    Log.e(TAG, "Failed after $maxRetries attempts due to exception")
                    Result.failure()
                }
            }
        }
    }

    private fun getActiveWidgetIds(): List<Int> {
        val widgetIds = mutableListOf<Int>()
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Check all possible widget IDs (typically 1-1000 range)
        for (i in 1..1000) {
            val widgetData = prefs.getString("widget_$i", null)
            if (widgetData != null) {
                widgetIds.add(i)
            }
        }

        return widgetIds
    }

    private suspend fun updateWidgetWeather(widgetId: Int): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Updating weather for widget $widgetId")

                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val location = prefs.getString("widget_${widgetId}_location", null)

                Log.d(TAG, "Widget $widgetId location from prefs: $location")
                if (location.isNullOrEmpty()) {
                    Log.w(TAG, "No location configured for widget $widgetId")
                    return@withContext false
                }

                // Get weather data from direct API call
                val weatherData = try {
                    WidgetWeatherService.getWeatherData(context, location)
                } catch (e: Exception) {
                    Log.e(TAG, "Exception getting weather data for widget $widgetId", e)
                    null
                }

                if (weatherData != null) {
                    try {
                        // Save weather data
                        saveWeatherData(widgetId, weatherData)

                        // Update widget display
                        updateWidgetDisplay(widgetId)

                        Log.d(TAG, "Successfully updated widget $widgetId")
                        return@withContext true
                    } catch (e: Exception) {
                        Log.e(TAG, "Error saving/updating widget $widgetId", e)
                        return@withContext false
                    }
                } else {
                    Log.w(TAG, "Failed to get weather data for widget $widgetId")
                    return@withContext false
                }

            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error updating widget $widgetId", e)
                return@withContext false
            }
        }
    }

    private suspend fun getWeatherFromFlutter(location: String): WeatherInfo? {
        return withContext(Dispatchers.Main) {
            try {
                // Create a background channel to communicate with Flutter
                val flutterEngine = FlutterEngine(context)
                flutterEngine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )

                val channel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    CHANNEL_NAME
                )

                var result: WeatherInfo? = null

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
                                    result = WeatherInfo(
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
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error parsing weather result", e)
                                }
                            }
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            Log.e(TAG, "Error from Flutter channel: $errorCode - $errorMessage")
                        }

                        override fun notImplemented() {
                            Log.w(TAG, "Method $METHOD_GET_WEATHER not implemented in Flutter")
                        }
                    }
                )

                // Wait for the result with timeout
                val startTime = System.currentTimeMillis()
                while (result == null && (System.currentTimeMillis() - startTime) < 10000) { // 10 second timeout
                    Thread.sleep(100)
                }

                flutterEngine.destroy()

                result
            } catch (e: Exception) {
                Log.e(TAG, "Error communicating with Flutter", e)
                null
            }
        }
    }

    private fun saveWeatherData(widgetId: Int, weatherInfo: WeatherInfo) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("widget_$widgetId", weatherInfo.toJson())
            .putLong("widget_${widgetId}_last_update", System.currentTimeMillis())
            .apply()

        Log.d(TAG, "Saved weather data for widget $widgetId")
    }

    private fun updateWidgetDisplay(widgetId: Int) {
        val intent = android.content.Intent(context, WeatherWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
        }
        context.sendBroadcast(intent)
    }

    private fun getCurrentTimeString(): String {
        val showSeconds = WidgetUpdateSettings.shouldShowSeconds(context)
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