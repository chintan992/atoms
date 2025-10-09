import 'package:equatable/equatable.dart';
import 'weather_models.dart';

/// Weather alert model
class WeatherAlert extends Equatable {
  final String headline;
  final String event;
  final String severity;
  final String areas;
  final String? description;
  final DateTime? effective;
  final DateTime? expires;

  const WeatherAlert({
    required this.headline,
    required this.event,
    required this.severity,
    required this.areas,
    this.description,
    this.effective,
    this.expires,
  });

  @override
  List<Object?> get props => [headline, event, severity, areas, description, effective, expires];

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) => s != null && s.isNotEmpty ? DateTime.tryParse(s) : null;
    return WeatherAlert(
      headline: json['headline'] ?? json['event'] ?? '',
      event: json['event'] ?? '',
      severity: json['severity'] ?? '',
      areas: json['areas'] ?? '',
      description: json['desc'] ?? json['description'],
      effective: parseDate(json['effective']),
      expires: parseDate(json['expires']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'event': event,
      'severity': severity,
      'areas': areas,
      'desc': description,
      'effective': effective?.toIso8601String(),
      'expires': expires?.toIso8601String(),
    };
  }
}

/// Astro data model
class Astro extends Equatable {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final int moonIllumination;

  const Astro({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.moonIllumination,
  });

  @override
  List<Object?> get props => [
    sunrise,
    sunset,
    moonrise,
    moonset,
    moonPhase,
    moonIllumination,
  ];

  factory Astro.fromJson(Map<String, dynamic> json) {
    return Astro(
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
      moonrise: json['moonrise'] ?? '',
      moonset: json['moonset'] ?? '',
      moonPhase: json['moon_phase'] ?? '',
      moonIllumination: json['moon_illumination'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'moon_phase': moonPhase,
      'moon_illumination': moonIllumination,
    };
  }
}

/// Forecast day model
class ForecastDay extends Equatable {
  final String date;
  final int dateEpoch;
  final Astro astro;
  final double maxtempC;
  final double maxtempF;
  final double mintempC;
  final double mintempF;
  final double avgtempC;
  final double avgtempF;
  final double maxwindMph;
  final double maxwindKph;
  final double totalprecipMm;
  final double totalprecipIn;
  final double avgvisKm;
  final double avgvisMiles;
  final double avghumidity;
  final int dailyWillItRain;
  final int dailyChanceOfRain;
  final int dailyWillItSnow;
  final int dailyChanceOfSnow;
  final double uv;
  final WeatherCondition condition;
  final List<HourForecast> hour;

  const ForecastDay({
    required this.date,
    required this.dateEpoch,
    required this.astro,
    required this.maxtempC,
    required this.maxtempF,
    required this.mintempC,
    required this.mintempF,
    required this.avgtempC,
    required this.avgtempF,
    required this.maxwindMph,
    required this.maxwindKph,
    required this.totalprecipMm,
    required this.totalprecipIn,
    required this.avgvisKm,
    required this.avgvisMiles,
    required this.avghumidity,
    required this.dailyWillItRain,
    required this.dailyChanceOfRain,
    required this.dailyWillItSnow,
    required this.dailyChanceOfSnow,
    required this.uv,
    required this.condition,
    required this.hour,
  });

  @override
  List<Object?> get props => [
    date,
    dateEpoch,
    astro,
    maxtempC,
    maxtempF,
    mintempC,
    mintempF,
    avgtempC,
    avgtempF,
    maxwindMph,
    maxwindKph,
    totalprecipMm,
    totalprecipIn,
    avgvisKm,
    avgvisMiles,
    avghumidity,
    dailyWillItRain,
    dailyChanceOfRain,
    dailyWillItSnow,
    dailyChanceOfSnow,
    uv,
    condition,
    hour,
  ];

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date'] ?? '',
      dateEpoch: json['date_epoch'] ?? 0,
      astro: Astro.fromJson(json['astro'] ?? {}),
      maxtempC: (json['day']['maxtemp_c'] ?? 0).toDouble(),
      maxtempF: (json['day']['maxtemp_f'] ?? 0).toDouble(),
      mintempC: (json['day']['mintemp_c'] ?? 0).toDouble(),
      mintempF: (json['day']['mintemp_f'] ?? 0).toDouble(),
      avgtempC: (json['day']['avgtemp_c'] ?? 0).toDouble(),
      avgtempF: (json['day']['avgtemp_f'] ?? 0).toDouble(),
      maxwindMph: (json['day']['maxwind_mph'] ?? 0).toDouble(),
      maxwindKph: (json['day']['maxwind_kph'] ?? 0).toDouble(),
      totalprecipMm: (json['day']['totalprecip_mm'] ?? 0).toDouble(),
      totalprecipIn: (json['day']['totalprecip_in'] ?? 0).toDouble(),
      avgvisKm: (json['day']['avgvis_km'] ?? 0).toDouble(),
      avgvisMiles: (json['day']['avgvis_miles'] ?? 0).toDouble(),
      avghumidity: (json['day']['avghumidity'] ?? 0).toDouble(),
      dailyWillItRain: json['day']['daily_will_it_rain'] ?? 0,
      dailyChanceOfRain: json['day']['daily_chance_of_rain'] ?? 0,
      dailyWillItSnow: json['day']['daily_will_it_snow'] ?? 0,
      dailyChanceOfSnow: json['day']['daily_chance_of_snow'] ?? 0,
      uv: (json['day']['uv'] ?? 0).toDouble(),
      condition: WeatherCondition.fromJson(json['day']['condition'] ?? {}),
      hour: (json['hour'] as List<dynamic>?)
          ?.map((hourItem) => HourForecast.fromJson(hourItem))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'date_epoch': dateEpoch,
      'astro': astro.toJson(),
      'day': {
        'maxtemp_c': maxtempC,
        'maxtemp_f': maxtempF,
        'mintemp_c': mintempC,
        'mintemp_f': mintempF,
        'avgtemp_c': avgtempC,
        'avgtemp_f': avgtempF,
        'maxwind_mph': maxwindMph,
        'maxwind_kph': maxwindKph,
        'totalprecip_mm': totalprecipMm,
        'totalprecip_in': totalprecipIn,
        'avgvis_km': avgvisKm,
        'avgvis_miles': avgvisMiles,
        'avghumidity': avghumidity,
        'daily_will_it_rain': dailyWillItRain,
        'daily_chance_of_rain': dailyChanceOfRain,
        'daily_will_it_snow': dailyWillItSnow,
        'daily_chance_of_snow': dailyChanceOfSnow,
        'uv': uv,
        'condition': condition.toJson(),
      },
      'hour': hour.map((hourItem) => hourItem.toJson()).toList(),
    };
  }
}

/// Hour forecast model
class HourForecast extends Equatable {
  final int timeEpoch;
  final String time;
  final double tempC;
  final double tempF;
  final int isDay;
  final WeatherCondition condition;
  final double windMph;
  final double windKph;
  final String windDir;
  final double pressureMb;
  final double pressureIn;
  final double precipMm;
  final double precipIn;
  final int humidity;
  final int cloud;
  final double feelslikeC;
  final double feelslikeF;
  final double windchillC;
  final double windchillF;
  final double heatindexC;
  final double heatindexF;
  final double dewpointC;
  final double dewpointF;
  final int willItRain;
  final int chanceOfRain;
  final int willItSnow;
  final int chanceOfSnow;
  final double visKm;
  final double visMiles;
  final double uv;

  const HourForecast({
    required this.timeEpoch,
    required this.time,
    required this.tempC,
    required this.tempF,
    required this.isDay,
    required this.condition,
    required this.windMph,
    required this.windKph,
    required this.windDir,
    required this.pressureMb,
    required this.pressureIn,
    required this.precipMm,
    required this.precipIn,
    required this.humidity,
    required this.cloud,
    required this.feelslikeC,
    required this.feelslikeF,
    required this.windchillC,
    required this.windchillF,
    required this.heatindexC,
    required this.heatindexF,
    required this.dewpointC,
    required this.dewpointF,
    required this.willItRain,
    required this.chanceOfRain,
    required this.willItSnow,
    required this.chanceOfSnow,
    required this.visKm,
    required this.visMiles,
    required this.uv,
  });

  @override
  List<Object?> get props => [
    timeEpoch,
    time,
    tempC,
    tempF,
    isDay,
    condition,
    windMph,
    windKph,
    windDir,
    pressureMb,
    pressureIn,
    precipMm,
    precipIn,
    humidity,
    cloud,
    feelslikeC,
    feelslikeF,
    windchillC,
    windchillF,
    heatindexC,
    heatindexF,
    dewpointC,
    dewpointF,
    willItRain,
    chanceOfRain,
    willItSnow,
    chanceOfSnow,
    visKm,
    visMiles,
    uv,
  ];

  factory HourForecast.fromJson(Map<String, dynamic> json) {
    return HourForecast(
      timeEpoch: json['time_epoch'] ?? 0,
      time: json['time'] ?? '',
      tempC: (json['temp_c'] ?? 0).toDouble(),
      tempF: (json['temp_f'] ?? 0).toDouble(),
      isDay: json['is_day'] ?? 0,
      condition: WeatherCondition.fromJson(json['condition'] ?? {}),
      windMph: (json['wind_mph'] ?? 0).toDouble(),
      windKph: (json['wind_kph'] ?? 0).toDouble(),
      windDir: json['wind_dir'] ?? '',
      pressureMb: (json['pressure_mb'] ?? 0).toDouble(),
      pressureIn: (json['pressure_in'] ?? 0).toDouble(),
      precipMm: (json['precip_mm'] ?? 0).toDouble(),
      precipIn: (json['precip_in'] ?? 0).toDouble(),
      humidity: json['humidity'] ?? 0,
      cloud: json['cloud'] ?? 0,
      feelslikeC: (json['feelslike_c'] ?? 0).toDouble(),
      feelslikeF: (json['feelslike_f'] ?? 0).toDouble(),
      windchillC: (json['windchill_c'] ?? 0).toDouble(),
      windchillF: (json['windchill_f'] ?? 0).toDouble(),
      heatindexC: (json['heatindex_c'] ?? 0).toDouble(),
      heatindexF: (json['heatindex_f'] ?? 0).toDouble(),
      dewpointC: (json['dewpoint_c'] ?? 0).toDouble(),
      dewpointF: (json['dewpoint_f'] ?? 0).toDouble(),
      willItRain: json['will_it_rain'] ?? 0,
      chanceOfRain: json['chance_of_rain'] ?? 0,
      willItSnow: json['will_it_snow'] ?? 0,
      chanceOfSnow: json['chance_of_snow'] ?? 0,
      visKm: (json['vis_km'] ?? 0).toDouble(),
      visMiles: (json['vis_miles'] ?? 0).toDouble(),
      uv: (json['uv'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_epoch': timeEpoch,
      'time': time,
      'temp_c': tempC,
      'temp_f': tempF,
      'is_day': isDay,
      'condition': condition.toJson(),
      'wind_mph': windMph,
      'wind_kph': windKph,
      'wind_dir': windDir,
      'pressure_mb': pressureMb,
      'pressure_in': pressureIn,
      'precip_mm': precipMm,
      'precip_in': precipIn,
      'humidity': humidity,
      'cloud': cloud,
      'feelslike_c': feelslikeC,
      'feelslike_f': feelslikeF,
      'windchill_c': windchillC,
      'windchill_f': windchillF,
      'heatindex_c': heatindexC,
      'heatindex_f': heatindexF,
      'dewpoint_c': dewpointC,
      'dewpoint_f': dewpointF,
      'will_it_rain': willItRain,
      'chance_of_rain': chanceOfRain,
      'will_it_snow': willItSnow,
      'chance_of_snow': chanceOfSnow,
      'vis_km': visKm,
      'vis_miles': visMiles,
      'uv': uv,
    };
  }
}

/// Forecast data model
class Forecast extends Equatable {
  final List<ForecastDay> forecastday;
  final List<HourForecast>? hourlyForecast;

  const Forecast({
    required this.forecastday,
    this.hourlyForecast,
  });

  @override
  List<Object?> get props => [forecastday, hourlyForecast];

  factory Forecast.fromJson(Map<String, dynamic> json) {
    final forecastDayList = (json['forecastday'] as List<dynamic>?)
        ?.map((day) => ForecastDay.fromJson(day))
        .toList();

    // Extract hourly forecast from the first day if needed
    final List<HourForecast>? hourlyForecastList = forecastDayList?.isNotEmpty == true
        ? (forecastDayList![0].toJson()['hour'] as List<dynamic>?)
            ?.map((hour) => HourForecast.fromJson(hour))
            .toList()
        : null;

    return Forecast(
      forecastday: forecastDayList ?? [],
      hourlyForecast: hourlyForecastList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forecastday': forecastday.map((day) => day.toJson()).toList(),
    };
  }
}

/// Enhanced weather data model that includes forecast
class EnhancedWeatherData extends Equatable {
  final Location location;
  final CurrentWeather current;
  final Forecast? forecast;
  final List<WeatherAlert>? alerts;

  const EnhancedWeatherData({
    required this.location,
    required this.current,
    this.forecast,
    this.alerts,
  });

  @override
  List<Object?> get props => [location, current, forecast, alerts];

  factory EnhancedWeatherData.fromJson(Map<String, dynamic> json) {
    List<WeatherAlert>? parseAlerts(dynamic alertsValue) {
      if (alertsValue == null) return null;
      // WeatherAPI may return either {"alert": [...]} or [] when none
      if (alertsValue is List) {
        if (alertsValue.isEmpty) return const [];
        return alertsValue
            .whereType<Map<String, dynamic>>()
            .map((e) => WeatherAlert.fromJson(e))
            .toList();
      }
      if (alertsValue is Map<String, dynamic>) {
        final list = alertsValue['alert'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => WeatherAlert.fromJson(e))
              .toList();
        }
        return const [];
      }
      return const [];
    }

    return EnhancedWeatherData(
      location: Location.fromJson(json['location'] ?? {}),
      current: CurrentWeather.fromJson(json['current'] ?? {}),
      forecast: json['forecast'] != null ? Forecast.fromJson(json['forecast']) : null,
      alerts: parseAlerts(json['alerts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'current': current.toJson(),
      'forecast': forecast?.toJson(),
      'alerts': alerts?.map((a) => a.toJson()).toList(),
    };
  }
}