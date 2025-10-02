import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atmos/core/config/app_config.dart';

class SettingsProvider extends ChangeNotifier {
  TemperatureUnit _temperatureUnit = AppConfig.defaultTemperatureUnit;
  AppThemeMode _themeMode = AppConfig.themeMode;
  String _defaultLocation = AppConfig.defaultLocation;
  double _defaultLocationLat = AppConfig.defaultLocationLat;
  double _defaultLocationLon = AppConfig.defaultLocationLon;
  int _updateIntervalMinutes = AppConfig.defaultUpdateIntervalMinutes;
  bool _widgetShowLocation = AppConfig.widgetShowLocation;
  bool _widgetShowCondition = AppConfig.widgetShowCondition;
  bool _isLoading = false;

  TemperatureUnit get temperatureUnit => _temperatureUnit;
  AppThemeMode get themeMode => _themeMode;
  String get defaultLocation => _defaultLocation;
  double get defaultLocationLat => _defaultLocationLat;
  double get defaultLocationLon => _defaultLocationLon;
  int get updateIntervalMinutes => _updateIntervalMinutes;
  bool get widgetShowLocation => _widgetShowLocation;
  bool get widgetShowCondition => _widgetShowCondition;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load temperature unit
      final unitIndex = prefs.getInt('temperature_unit') ??
          (AppConfig.defaultTemperatureUnit == TemperatureUnit.celsius ? 0 : 1);
      _temperatureUnit = TemperatureUnit.values[unitIndex];

      // Load theme mode
      final themeIndex = prefs.getInt('theme_mode') ??
          (AppConfig.themeMode == AppThemeMode.system ? 0 :
           AppConfig.themeMode == AppThemeMode.light ? 1 : 2);
      _themeMode = AppThemeMode.values[themeIndex];

      // Load location settings
      _defaultLocation = prefs.getString('default_location') ?? AppConfig.defaultLocation;
      _defaultLocationLat = prefs.getDouble('default_location_lat') ?? AppConfig.defaultLocationLat;
      _defaultLocationLon = prefs.getDouble('default_location_lon') ?? AppConfig.defaultLocationLon;

      // Load update interval
      _updateIntervalMinutes = prefs.getInt('update_interval_minutes') ?? AppConfig.defaultUpdateIntervalMinutes;

      // Load widget settings
      _widgetShowLocation = prefs.getBool('widget_show_location') ?? AppConfig.widgetShowLocation;
      _widgetShowCondition = prefs.getBool('widget_show_condition') ?? AppConfig.widgetShowCondition;

    } catch (e) {
      // Use default values if loading fails
      if (AppConfig.debugMode) {
        print('SettingsProvider: Error loading settings: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    if (_temperatureUnit == unit) return;

    _temperatureUnit = unit;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('temperature_unit', unit.index);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _temperatureUnit = _temperatureUnit == TemperatureUnit.celsius
          ? TemperatureUnit.fahrenheit
          : TemperatureUnit.celsius;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _themeMode = AppConfig.themeMode;
      notifyListeners();
    }
  }

  Future<void> setDefaultLocation(String location, {double? lat, double? lon}) async {
    if (_defaultLocation == location &&
        _defaultLocationLat == (lat ?? _defaultLocationLat) &&
        _defaultLocationLon == (lon ?? _defaultLocationLon)) {
      return;
    }

    _defaultLocation = location;
    if (lat != null) _defaultLocationLat = lat;
    if (lon != null) _defaultLocationLon = lon;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_location', location);
      await prefs.setDouble('default_location_lat', _defaultLocationLat);
      await prefs.setDouble('default_location_lon', _defaultLocationLon);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _defaultLocation = AppConfig.defaultLocation;
      _defaultLocationLat = AppConfig.defaultLocationLat;
      _defaultLocationLon = AppConfig.defaultLocationLon;
      notifyListeners();
    }
  }

  Future<void> setUpdateIntervalMinutes(int minutes) async {
    if (_updateIntervalMinutes == minutes) return;

    _updateIntervalMinutes = minutes;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('update_interval_minutes', minutes);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _updateIntervalMinutes = AppConfig.defaultUpdateIntervalMinutes;
      notifyListeners();
    }
  }

  Future<void> setWidgetShowLocation(bool show) async {
    if (_widgetShowLocation == show) return;

    _widgetShowLocation = show;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('widget_show_location', show);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _widgetShowLocation = AppConfig.widgetShowLocation;
      notifyListeners();
    }
  }

  Future<void> setWidgetShowCondition(bool show) async {
    if (_widgetShowCondition == show) return;

    _widgetShowCondition = show;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('widget_show_condition', show);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _widgetShowCondition = AppConfig.widgetShowCondition;
      notifyListeners();
    }
  }

  String getTemperatureDisplay(double celsius, double fahrenheit) {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return '${celsius.round()}°C';
      case TemperatureUnit.fahrenheit:
        return '${fahrenheit.round()}°F';
    }
  }

  double getTemperatureValue(double celsius, double fahrenheit) {
    switch (_temperatureUnit) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return fahrenheit;
    }
  }
}