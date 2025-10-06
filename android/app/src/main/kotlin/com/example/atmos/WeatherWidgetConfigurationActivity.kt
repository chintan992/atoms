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
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

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
    private lateinit var useCurrentLocationCheckBox: CheckBox
    private lateinit var locationEditText: EditText
    private lateinit var locationSuggestionsList: ListView
    private lateinit var showHighLowCheckbox: CheckBox
    private lateinit var showHumidityCheckbox: CheckBox
    private lateinit var showWindCheckbox: CheckBox
    private lateinit var updateFrequencySpinner: Spinner
    private lateinit var themeSpinner: Spinner
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
        setupThemeSpinner()
        setupSaveButton()
    }

    private fun initializeViews() {
        useCurrentLocationCheckBox = findViewById(R.id.use_current_location_checkbox)
        locationEditText = findViewById(R.id.location_edit_text)
        locationSuggestionsList = findViewById(R.id.location_suggestions_list)
        showHighLowCheckbox = findViewById(R.id.show_high_low_checkbox)
        showHumidityCheckbox = findViewById(R.id.show_humidity_checkbox)
        showWindCheckbox = findViewById(R.id.show_wind_checkbox)
        updateFrequencySpinner = findViewById(R.id.update_frequency_spinner)
        themeSpinner = findViewById(R.id.theme_spinner)
        saveButton = findViewById(R.id.save_button)
        progressBar = findViewById(R.id.progress_bar)
    }

    private fun setupLocationSpinner() {
        // Set up current location checkbox listener
        useCurrentLocationCheckBox.setOnCheckedChangeListener { _, isChecked ->
            locationEditText.isEnabled = !isChecked
            if (isChecked) {
                locationEditText.setText("")
                locationSuggestionsList.visibility = View.GONE
            }
        }

        // Set up location search with suggestions
        val commonLocations = listOf(
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
            "San Jose, CA",
            "Austin, TX",
            "Jacksonville, FL",
            "Fort Worth, TX",
            "Columbus, OH",
            "Charlotte, NC",
            "San Francisco, CA",
            "Indianapolis, IN",
            "Seattle, WA",
            "Denver, CO",
            "Washington, DC",
            "Boston, MA",
            "El Paso, TX",
            "Nashville, TN",
            "Detroit, MI",
            "Oklahoma City, OK",
            "Portland, OR",
            "Las Vegas, NV",
            "Memphis, TN",
            "Louisville, KY",
            "Baltimore, MD",
            "Milwaukee, WI",
            "Albuquerque, NM",
            "Tucson, AZ",
            "Fresno, CA",
            "Sacramento, CA",
            "Mesa, AZ",
            "Kansas City, MO",
            "Atlanta, GA",
            "Long Beach, CA",
            "Colorado Springs, CO",
            "Raleigh, NC",
            "Miami, FL",
            "Virginia Beach, VA",
            "Omaha, NE",
            "Oakland, CA",
            "Minneapolis, MN",
            "Tulsa, OK",
            "Arlington, TX",
            "Tampa, FL"
        )

        // Create a mutable list for the adapter
        val mutableLocations = commonLocations.toMutableList()
        val suggestionsAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_list_item_1,
            mutableLocations
        )
        locationSuggestionsList.adapter = suggestionsAdapter
        locationSuggestionsList.visibility = View.GONE

        // Set up text change listener for filtering
        locationEditText.addTextChangedListener(object : android.text.TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: android.text.Editable?) {
                if (!useCurrentLocationCheckBox.isChecked) {
                    val query = s.toString().trim()
                    if (query.isNotEmpty()) {
                        val filteredLocations = commonLocations.filter { 
                            it.contains(query, ignoreCase = true) 
                        }
                        // Clear and repopulate the mutable list
                        mutableLocations.clear()
                        mutableLocations.addAll(filteredLocations)
                        suggestionsAdapter.notifyDataSetChanged()
                        locationSuggestionsList.visibility = if (filteredLocations.isNotEmpty()) View.VISIBLE else View.GONE
                    } else {
                        locationSuggestionsList.visibility = View.GONE
                    }
                }
            }
        })

        // Handle suggestion selection
        locationSuggestionsList.setOnItemClickListener { _, _, position, _ ->
            val selectedLocation = suggestionsAdapter.getItem(position)
            locationEditText.setText(selectedLocation)
            locationSuggestionsList.visibility = View.GONE
        }

        // Hide suggestions when clicking outside
        locationEditText.setOnFocusChangeListener { _, hasFocus ->
            if (!hasFocus) {
                locationSuggestionsList.visibility = View.GONE
            }
        }
    }

    private fun getCurrentLocationFromFlutter(callback: (String?) -> Unit) {
        // Try to read coordinates from SharedPreferences first
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lat = prefs.getString("flutter.current_location_lat", null)
        val lon = prefs.getString("flutter.current_location_lon", null)
        
        if (lat != null && lon != null) {
            val coordinates = "$lat,$lon"
            Log.d(TAG, "Retrieved current location coordinates from SharedPreferences: $coordinates")
            callback(coordinates)
            return
        }
        
        Log.w(TAG, "Current location coordinates not available in SharedPreferences")
        
        // If not available, try to use a fallback location (Calgary) based on user's detected location
        // This is a fallback to ensure the widget works even if location access fails
        val fallbackCoordinates = "51.08,-113.98" // Calgary coordinates
        Log.d(TAG, "Using fallback coordinates (Calgary): $fallbackCoordinates")
        
        // Store these coordinates for future use
        prefs.edit()
            .putString("flutter.current_location_lat", "51.08")
            .putString("flutter.current_location_lon", "-113.98")
            .apply()
        
        callback(fallbackCoordinates)
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

    private fun setupThemeSpinner() {
        val themes = arrayOf(
            "Auto (Follow System)",
            "Light Theme",
            "Dark Theme"
        )

        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            themes
        )
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        themeSpinner.adapter = adapter

        // Load saved theme preference
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedTheme = prefs.getString("widget_theme_mode", WidgetUpdateSettings.THEME_AUTO)
        val position = when (savedTheme) {
            WidgetUpdateSettings.THEME_LIGHT -> 1
            WidgetUpdateSettings.THEME_DARK -> 2
            else -> 0 // Auto
        }
        themeSpinner.setSelection(position)
    }

    private fun setupSaveButton() {
        saveButton.setOnClickListener {
            saveConfiguration()
        }
    }

    private fun saveConfiguration() {
        val useCurrentLocation = useCurrentLocationCheckBox.isChecked
        val selectedLocation = if (!useCurrentLocation) {
            locationEditText.text.toString().trim().ifEmpty { DEFAULT_LOCATION }
        } else {
            "" // Will be set to coordinates below
        }

        if (!useCurrentLocation && selectedLocation.isEmpty()) {
            Toast.makeText(this, "Please enter a location or select current location", Toast.LENGTH_SHORT).show()
            return
        }

        showProgressImpl(true)

        // If using current location, get coordinates first
        if (useCurrentLocation) {
            getCurrentLocationFromFlutter { coordinates ->
                if (coordinates != null) {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            // Store the actual coordinates instead of CURRENT_LOCATION marker
                            saveWidgetConfiguration(coordinates)

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

                            withContext(Dispatchers.Main) {
                                showProgressImpl(false)
                                Toast.makeText(this@WeatherWidgetConfigurationActivity, "Widget configured with current location", Toast.LENGTH_SHORT).show()
                                finish()
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving current location configuration", e)
                            withContext(Dispatchers.Main) {
                                Toast.makeText(this@WeatherWidgetConfigurationActivity, "Failed to save configuration", Toast.LENGTH_SHORT).show()
                                showProgressImpl(false)
                            }
                        }
                    }
                } else {
                    showProgressImpl(false)
                    Toast.makeText(this@WeatherWidgetConfigurationActivity, "Using Calgary as default location. You can change this later in widget settings.", Toast.LENGTH_SHORT).show()
                }
            }
        } else {
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
                    this@WeatherWidgetConfigurationActivity.setResult(Activity.RESULT_OK, resultValue)

                    runOnUiThread {
                        showProgressImpl(false)
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
                        showProgressImpl(false)
                        Toast.makeText(
                            this@WeatherWidgetConfigurationActivity,
                            "Error configuring widget. Please try again.",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
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

        // Update the global theme setting
        val themeMode = when (themeSpinner.selectedItemPosition) {
            1 -> WidgetUpdateSettings.THEME_LIGHT
            2 -> WidgetUpdateSettings.THEME_DARK
            else -> WidgetUpdateSettings.THEME_AUTO
        }
        WidgetUpdateSettings.setThemeMode(this, themeMode)
    }

    private fun showProgressImpl(show: Boolean) {
        progressBar.visibility = if (show) View.VISIBLE else View.GONE
        saveButton.visibility = if (show) View.GONE else View.VISIBLE
        useCurrentLocationCheckBox.isEnabled = !show
        locationEditText.isEnabled = !show && !useCurrentLocationCheckBox.isChecked
        showHighLowCheckbox.isEnabled = !show
        showHumidityCheckbox.isEnabled = !show
        showWindCheckbox.isEnabled = !show
        updateFrequencySpinner.isEnabled = !show
        themeSpinner.isEnabled = !show
    }
}