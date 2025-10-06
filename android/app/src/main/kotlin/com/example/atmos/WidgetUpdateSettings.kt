package com.example.atmos

import android.content.Context
import android.content.SharedPreferences
import androidx.preference.PreferenceManager

/**
 * Settings manager for widget update configuration
 */
object WidgetUpdateSettings {

    private const val PREF_UPDATE_INTERVAL = "widget_update_interval_minutes"
    private const val PREF_BATTERY_OPTIMIZATION = "widget_battery_optimization"
    private const val PREF_WIFI_ONLY = "widget_wifi_only"
    private const val PREF_MAX_RETRIES = "widget_max_retries"
    private const val PREF_THEME_MODE = "widget_theme_mode"
    private const val PREF_TEXT_SIZE = "widget_text_size"
    private const val PREF_SHOW_SECONDS = "widget_show_seconds"

    // Default values
    const val DEFAULT_UPDATE_INTERVAL = 30L // minutes
    const val MIN_UPDATE_INTERVAL = 15L // minutes
    const val MAX_UPDATE_INTERVAL = 360L // minutes (6 hours)
    
    // Theme modes
    const val THEME_AUTO = "auto"
    const val THEME_LIGHT = "light"
    const val THEME_DARK = "dark"
    
    // Text sizes
    const val TEXT_SIZE_SMALL = "small"
    const val TEXT_SIZE_MEDIUM = "medium"
    const val TEXT_SIZE_LARGE = "large"

    private fun getPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    /**
     * Get the configured update interval in minutes
     */
    fun getUpdateIntervalMinutes(context: Context): Long {
        return getPreferences(context).getLong(PREF_UPDATE_INTERVAL, DEFAULT_UPDATE_INTERVAL)
    }

    /**
     * Set the update interval in minutes
     */
    fun setUpdateIntervalMinutes(context: Context, minutes: Long) {
        val clampedMinutes = minutes.coerceIn(MIN_UPDATE_INTERVAL, MAX_UPDATE_INTERVAL)
        getPreferences(context).edit()
            .putLong(PREF_UPDATE_INTERVAL, clampedMinutes)
            .apply()
    }

    /**
     * Check if battery optimization is enabled
     */
    fun isBatteryOptimizationEnabled(context: Context): Boolean {
        return getPreferences(context).getBoolean(PREF_BATTERY_OPTIMIZATION, true)
    }

    /**
     * Set battery optimization preference
     */
    fun setBatteryOptimizationEnabled(context: Context, enabled: Boolean) {
        getPreferences(context).edit()
            .putBoolean(PREF_BATTERY_OPTIMIZATION, enabled)
            .apply()
    }

    /**
     * Check if WiFi-only mode is enabled
     */
    fun isWifiOnlyEnabled(context: Context): Boolean {
        return getPreferences(context).getBoolean(PREF_WIFI_ONLY, false)
    }

    /**
     * Set WiFi-only preference
     */
    fun setWifiOnlyEnabled(context: Context, enabled: Boolean) {
        getPreferences(context).edit()
            .putBoolean(PREF_WIFI_ONLY, enabled)
            .apply()
    }

    /**
     * Get maximum retry attempts for failed updates
     */
    fun getMaxRetries(context: Context): Int {
        return getPreferences(context).getInt(PREF_MAX_RETRIES, 3)
    }

    /**
     * Set maximum retry attempts
     */
    fun setMaxRetries(context: Context, maxRetries: Int) {
        getPreferences(context).edit()
            .putInt(PREF_MAX_RETRIES, maxRetries.coerceIn(1, 10))
            .apply()
    }

    /**
     * Get the current theme mode
     */
    fun getThemeMode(context: Context): String {
        return getPreferences(context).getString(PREF_THEME_MODE, THEME_AUTO) ?: THEME_AUTO
    }

    /**
     * Set the theme mode
     */
    fun setThemeMode(context: Context, themeMode: String) {
        getPreferences(context).edit()
            .putString(PREF_THEME_MODE, themeMode)
            .apply()
    }

    /**
     * Get the text size preference
     */
    fun getTextSize(context: Context): String {
        return getPreferences(context).getString(PREF_TEXT_SIZE, TEXT_SIZE_MEDIUM) ?: TEXT_SIZE_MEDIUM
    }

    /**
     * Set the text size preference
     */
    fun setTextSize(context: Context, textSize: String) {
        getPreferences(context).edit()
            .putString(PREF_TEXT_SIZE, textSize)
            .apply()
    }

    /**
     * Check if seconds should be shown in time
     */
    fun shouldShowSeconds(context: Context): Boolean {
        return getPreferences(context).getBoolean(PREF_SHOW_SECONDS, false)
    }

    /**
     * Set whether to show seconds in time
     */
    fun setShowSeconds(context: Context, showSeconds: Boolean) {
        getPreferences(context).edit()
            .putBoolean(PREF_SHOW_SECONDS, showSeconds)
            .apply()
    }

    /**
     * Get all current settings as a map for debugging
     */
    fun getAllSettings(context: Context): Map<String, Any?> {
        val prefs = getPreferences(context)
        return mapOf(
            PREF_UPDATE_INTERVAL to prefs.getLong(PREF_UPDATE_INTERVAL, DEFAULT_UPDATE_INTERVAL),
            PREF_BATTERY_OPTIMIZATION to prefs.getBoolean(PREF_BATTERY_OPTIMIZATION, true),
            PREF_WIFI_ONLY to prefs.getBoolean(PREF_WIFI_ONLY, false),
            PREF_MAX_RETRIES to prefs.getInt(PREF_MAX_RETRIES, 3),
            PREF_THEME_MODE to prefs.getString(PREF_THEME_MODE, THEME_AUTO),
            PREF_TEXT_SIZE to prefs.getString(PREF_TEXT_SIZE, TEXT_SIZE_MEDIUM),
            PREF_SHOW_SECONDS to prefs.getBoolean(PREF_SHOW_SECONDS, false)
        )
    }

    /**
     * Reset all settings to default values
     */
    fun resetToDefaults(context: Context) {
        getPreferences(context).edit()
            .remove(PREF_UPDATE_INTERVAL)
            .remove(PREF_BATTERY_OPTIMIZATION)
            .remove(PREF_WIFI_ONLY)
            .remove(PREF_MAX_RETRIES)
            .remove(PREF_THEME_MODE)
            .remove(PREF_TEXT_SIZE)
            .remove(PREF_SHOW_SECONDS)
            .apply()
    }
}