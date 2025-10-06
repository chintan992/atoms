package com.example.atmos

import org.json.JSONObject

data class WeatherInfo(
    val temperature: String,
    val condition: String,
    val location: String,
    val lastUpdated: String,
    val iconResId: Int? = null,
    val highTemp: String = "--°",
    val lowTemp: String = "--°",
    val humidity: String = "--%",
    val windSpeed: String = "-- km/h",
    val feelsLike: String = "--°"
) {

    fun toJson(): String {
        return JSONObject().apply {
            put("temperature", temperature)
            put("condition", condition)
            put("location", location)
            put("lastUpdated", lastUpdated)
            put("iconResId", iconResId)
            put("highTemp", highTemp)
            put("lowTemp", lowTemp)
            put("humidity", humidity)
            put("windSpeed", windSpeed)
            put("feelsLike", feelsLike)
        }.toString()
    }

    companion object {
        fun fromJson(json: String): WeatherInfo {
            val jsonObject = JSONObject(json)
            return WeatherInfo(
                temperature = jsonObject.getString("temperature"),
                condition = jsonObject.getString("condition"),
                location = jsonObject.getString("location"),
                lastUpdated = jsonObject.getString("lastUpdated"),
                iconResId = if (jsonObject.has("iconResId")) jsonObject.getInt("iconResId") else null,
                highTemp = if (jsonObject.has("highTemp")) jsonObject.optString("highTemp", "--°") else "--°",
                lowTemp = if (jsonObject.has("lowTemp")) jsonObject.optString("lowTemp", "--°") else "--°",
                humidity = if (jsonObject.has("humidity")) jsonObject.optString("humidity", "--%") else "--%",
                windSpeed = if (jsonObject.has("windSpeed")) jsonObject.optString("windSpeed", "-- km/h") else "-- km/h",
                feelsLike = if (jsonObject.has("feelsLike")) jsonObject.optString("feelsLike", "--°") else "--°"
            )
        }
    }
}