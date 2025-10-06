package com.example.atmos

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

object WidgetWeatherService {
    private const val TAG = "WidgetWeatherService"
    private const val API_BASE_URL = "https://api.weatherapi.com/v1"
    
    // Get API key from Flutter app's shared preferences
    private fun getApiKey(context: Context): String {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val apiKey = prefs.getString("flutter.WEATHER_API_KEY", "") ?: ""
        Log.d(TAG, "Retrieved API key length: ${apiKey.length}")
        
        // Debug: Log all preferences to see what's stored
        if (apiKey.isEmpty()) {
            Log.w(TAG, "API key is empty, checking all stored preferences:")
            val allPrefs = prefs.all
            for ((key, value) in allPrefs) {
                if (key.contains("API") || key.contains("KEY") || key.contains("WEATHER")) {
                    Log.d(TAG, "Found preference: $key = ${value.toString().take(10)}...")
                }
            }
        }
        
        return apiKey
    }

    // Get temperature unit preference (0 = Celsius, 1 = Fahrenheit)
    private fun getTemperatureUnit(context: Context): Int {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val unit = prefs.getLong("flutter.temperature_unit", 0L).toInt() // Default to Celsius (0)
        Log.d(TAG, "Temperature unit preference: $unit (0=Celsius, 1=Fahrenheit)")
        return unit
    }

    // Get current location coordinates from Flutter app's shared preferences
    private fun getCurrentLocationCoordinates(context: Context): String? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lat = prefs.getString("flutter.current_location_lat", null)
        val lon = prefs.getString("flutter.current_location_lon", null)

        return if (lat != null && lon != null) {
            "$lat,$lon"
        } else {
            null
        }
    }
    
    suspend fun getWeatherData(context: Context, location: String): WeatherInfo? {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Fetching weather for location: $location")

                val apiKey = getApiKey(context)
                Log.d(TAG, "API key length: ${apiKey.length}")
                if (apiKey.isEmpty()) {
                    Log.e(TAG, "API key not found in shared preferences")
                    return@withContext null
                }

                val url = "$API_BASE_URL/current.json?key=$apiKey&q=$location&aqi=no"
                Log.d(TAG, "Making request to URL: $url")
                val connection = URL(url).openConnection() as HttpURLConnection
                
                connection.requestMethod = "GET"
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                
                val responseCode = connection.responseCode
                Log.d(TAG, "HTTP response code: $responseCode")
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    Log.d(TAG, "Response length: ${response.length}")
                    val jsonObject = JSONObject(response)
                    
                    val current = jsonObject.getJSONObject("current")
                    val locationObj = jsonObject.getJSONObject("location")

                    val temperatureUnit = getTemperatureUnit(context)
                    val tempC = current.getDouble("temp_c")
                    val tempF = current.getDouble("temp_f")
                    val temperature = if (temperatureUnit == 0) {
                        "${tempC.toInt()}°C"
                    } else {
                        "${tempF.toInt()}°F"
                    }
                    val condition = current.getJSONObject("condition").getString("text")
                    val locationName = locationObj.getString("name")
                    Log.d(TAG, "Raw temps: ${tempC}°C / ${tempF}°F, Unit: $temperatureUnit, Final: $temperature")
                    Log.d(TAG, "Parsed weather: $temperature, $condition, $locationName (Unit: $temperatureUnit)")
                    val humidity = "${current.getInt("humidity")}%"
                    val windSpeed = "${current.getDouble("wind_kph").toInt()} km/h"
                    val feelsLikeC = current.getDouble("feelslike_c")
                    val feelsLikeF = current.getDouble("feelslike_f")
                    val feelsLike = if (temperatureUnit == 0) {
                        "${feelsLikeC.toInt()}°C"
                    } else {
                        "${feelsLikeF.toInt()}°F"
                    }
                    Log.d(TAG, "Raw feels like: ${feelsLikeC}°C / ${feelsLikeF}°F, Final: $feelsLike")
                    
                    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                    val lastUpdated = timeFormat.format(Date())
                    
                    WeatherInfo(
                        temperature = temperature,
                        condition = condition,
                        location = locationName,
                        lastUpdated = lastUpdated,
                        iconResId = getWeatherIconResId(current.getJSONObject("condition").getString("icon")),
                        highTemp = temperature, // Current API doesn't provide high/low in current endpoint
                        lowTemp = temperature,
                        humidity = humidity,
                        windSpeed = windSpeed,
                        feelsLike = feelsLike
                    )
                } else {
                    Log.e(TAG, "HTTP error: $responseCode")
                    null
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching weather data", e)
                null
            }
        }
    }
    
    private fun getWeatherIconResId(iconUrl: String): Int {
        // Map weather API icons to local drawable resources
        return when {
            iconUrl.contains("sunny") || iconUrl.contains("clear") -> R.drawable.ic_weather_sunny
            iconUrl.contains("cloudy") -> R.drawable.ic_weather_cloudy
            iconUrl.contains("rain") -> R.drawable.ic_weather_rain
            iconUrl.contains("snow") -> R.drawable.ic_weather_snow
            iconUrl.contains("storm") || iconUrl.contains("thunder") -> R.drawable.ic_weather_thunderstorm
            iconUrl.contains("partly") -> R.drawable.ic_weather_partly_cloudy
            else -> R.drawable.ic_weather_default
        }
    }
}
