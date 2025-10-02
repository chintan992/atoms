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
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var locationSpinner: Spinner
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
        setupSaveButton()
    }

    private fun initializeViews() {
        locationSpinner = findViewById(R.id.location_spinner)
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

        prefs.edit()
            .putString("widget_${appWidgetId}_location", location)
            .putString("widget_$appWidgetId", null) // Clear any existing weather data
            .apply()

        Log.d(TAG, "Saved configuration for widget $appWidgetId with location: $location")
    }

    private fun showProgress(show: Boolean) {
        progressBar.visibility = if (show) View.VISIBLE else View.GONE
        saveButton.visibility = if (show) View.GONE else View.VISIBLE
        locationSpinner.isEnabled = !show
    }
}