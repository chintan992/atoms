package com.example.atmos

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.preference.PreferenceManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class WeatherWidgetConfigurationActivity : AppCompatActivity() {

    companion object {
        const val TAG = "WidgetConfigActivity"
        const val DEFAULT_LOCATION = "Current Location"
        private const val PREF_WIDGET_SHOW_HIGH_LOW = "widget_show_high_low_"
        private const val PREF_WIDGET_SHOW_HUMIDITY = "widget_show_humidity_"
        private const val PREF_WIDGET_SHOW_WIND = "widget_show_wind_"
        private const val PREF_WIDGET_UPDATE_FREQUENCY = "widget_update_frequency_"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var locationSpinner: Spinner
    private lateinit var showHighLowCheckbox: CheckBox
    private lateinit var showHumidityCheckbox: CheckBox
    private lateinit var showWindCheckbox: CheckBox
    private lateinit var updateFrequencySpinner: Spinner
    private lateinit var saveButton: Button
    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate")

        // Set result to cancelled in case user backs out
        setResult(Activity.RESULT_CANCELED)

        // Get the app widget ID from the intent
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        // If no valid widget ID, finish activity
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.activity_widget_configuration)

        initializeViews()
        setupLocationSpinner()
        setupDisplayOptions()
        setupUpdateFrequencySpinner()
        setupSaveButton()
    }

    private fun initializeViews() {
        locationSpinner = findViewById(R.id.location_spinner)
        showHighLowCheckbox = findViewById(R.id.show_high_low_checkbox)
        showHumidityCheckbox = findViewById(R.id.show_humidity_checkbox)
        showWindCheckbox = findViewById(R.id.show_wind_checkbox)
        updateFrequencySpinner = findViewById(R.id.update_frequency_spinner)
        saveButton = findViewById(R.id.save_button)
        progressBar = findViewById(R.id.progress_bar)
    }

    private fun setupLocationSpinner() {
        // For now, use a simple list of common locations
        // In a real app, this would come from user's saved locations or search
        val locations = arrayOf(
            DEFAULT_LOCATION,
            "New York, NY",
            "Los Angeles, CA",
            "Chicago, IL",
            "Houston, TX",
            "Phoenix, AZ",
            "Philadelphia, PA",
            "San Antonio, TX",
            "San Diego, CA",
            "Dallas, TX",
            "San Jose, CA"
        )

        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            locations
        )
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        locationSpinner.adapter = adapter
    }

    private fun setupDisplayOptions() {
        // Load saved display preferences for this widget
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        showHighLowCheckbox.isChecked = prefs.getBoolean("${PREF_WIDGET_SHOW_HIGH_LOW}$appWidgetId", true)
        showHumidityCheckbox.isChecked = prefs.getBoolean("${PREF_WIDGET_SHOW_HUMIDITY}$appWidgetId", true)
        showWindCheckbox.isChecked = prefs.getBoolean("${PREF_WIDGET_SHOW_WIND}$appWidgetId", true)
    }

    private fun setupUpdateFrequencySpinner() {
        // Options for update frequency in minutes
        val frequencies = arrayOf(
            "15 minutes", "30 minutes", "1 hour", "2 hours", "6 hours"
        )

        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            frequencies
        )
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        updateFrequencySpinner.adapter = adapter

        // Load saved frequency preference
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedFrequency = prefs.getString("${PREF_WIDGET_UPDATE_FREQUENCY}$appWidgetId", "30 minutes")
        val position = frequencies.indexOf(savedFrequency)
        if (position >= 0) {
            updateFrequencySpinner.setSelection(position)
        }
    }

    private fun setupSaveButton() {
        saveButton.setOnClickListener {
            saveConfiguration()
        }
    }

    private fun saveConfiguration() {
        val selectedLocation = locationSpinner.selectedItem.toString()

        if (selectedLocation.isEmpty()) {
            Toast.makeText(this, "Please select a location", Toast.LENGTH_SHORT).show()
            return
        }

        showProgress(true)

        CoroutineScope(Dispatchers.IO).launch {
            try {
                saveWidgetConfiguration(selectedLocation)

                // Update the widget
                val appWidgetManager = AppWidgetManager.getInstance(this@WeatherWidgetConfigurationActivity)
                WeatherWidgetProvider().onUpdate(
                    this@WeatherWidgetConfigurationActivity,
                    appWidgetManager,
                    intArrayOf(appWidgetId)
                )

                // Set result to successful
                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                setResult(Activity.RESULT_OK, resultValue)

                runOnUiThread {
                    showProgress(false)
                    Toast.makeText(
                        this@WeatherWidgetConfigurationActivity,
                        "Widget configured successfully",
                        Toast.LENGTH_SHORT
                    ).show()
                    finish()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error saving widget configuration", e)
                runOnUiThread {
                    showProgress(false)
                    Toast.makeText(
                        this@WeatherWidgetConfigurationActivity,
                        "Error configuring widget. Please try again.",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun saveWidgetConfiguration(location: String) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Save location and display options
        prefs.edit()
            .putString("widget_${appWidgetId}_location", location)
            .putBoolean("${PREF_WIDGET_SHOW_HIGH_LOW}$appWidgetId", showHighLowCheckbox.isChecked)
            .putBoolean("${PREF_WIDGET_SHOW_HUMIDITY}$appWidgetId", showHumidityCheckbox.isChecked)
            .putBoolean("${PREF_WIDGET_SHOW_WIND}$appWidgetId", showWindCheckbox.isChecked)
            .putString("${PREF_WIDGET_UPDATE_FREQUENCY}$appWidgetId", 
                when (updateFrequencySpinner.selectedItemPosition) {
                    0 -> "15"
                    1 -> "30"
                    2 -> "60"
                    3 -> "120"
                    4 -> "360"
                    else -> "30"
                }
            )
            .putString("widget_$appWidgetId", null) // Clear any existing weather data
            .apply()

        Log.d(TAG, "Saved configuration for widget $appWidgetId with location: $location")
        
        // Update the global update interval setting
        val updateMinutes = when (updateFrequencySpinner.selectedItemPosition) {
            0 -> 15L
            1 -> 30L
            2 -> 60L
            3 -> 120L
            4 -> 360L
            else -> 30L // Default
        }
        WidgetUpdateSettings.setUpdateIntervalMinutes(this, updateMinutes)
    }

    private fun showProgress(show: Boolean) {
        progressBar.visibility = if (show) View.VISIBLE else View.GONE
        saveButton.visibility = if (show) View.GONE else View.VISIBLE
        locationSpinner.isEnabled = !show
        showHighLowCheckbox.isEnabled = !show
        showHumidityCheckbox.isEnabled = !show
        showWindCheckbox.isEnabled = !show
        updateFrequencySpinner.isEnabled = !show
    }
}