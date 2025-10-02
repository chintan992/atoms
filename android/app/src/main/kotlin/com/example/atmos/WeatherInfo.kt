package com.example.atmos

import org.json.JSONObject

data class WeatherInfo(
    val temperature: String,
    val condition: String,
    val location: String,
    val lastUpdated: String,
    val iconResId: Int? = null
) {

    fun toJson(): String {
        return JSONObject().apply {
            put("temperature", temperature)
            put("condition", condition)
            put("location", location)
            put("lastUpdated", lastUpdated)
            put("iconResId", iconResId)
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
                iconResId = if (jsonObject.has("iconResId")) jsonObject.getInt("iconResId") else null
            )
        }
    }
}