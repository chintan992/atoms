import 'package:equatable/equatable.dart';

/// Main weather condition model
class WeatherCondition extends Equatable {
  final String text;
  final String icon;
  final int code;

  const WeatherCondition({
    required this.text,
    required this.icon,
    required this.code,
  });

  @override
  List<Object?> get props => [text, icon, code];

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      text: json['text'] ?? '',
      icon: json['icon'] ?? '',
      code: json['code'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'icon': icon,
      'code': code,
    };
  }
}

/// Current weather data model
class CurrentWeather extends Equatable {
  final double tempC;
  final double tempF;
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
  final double visKm;
  final double visMiles;
  final double uv;
  final double gustMph;
  final double gustKph;
  final int isDay;
  // Additional fields that might be present in forecast data
  final double? maxtempC;
  final double? maxtempF;
  final double? mintempC;
  final double? mintempF;
  final double? avgtempC;
  final double? avgtempF;

  const CurrentWeather({
    required this.tempC,
    required this.tempF,
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
    required this.visKm,
    required this.visMiles,
    required this.uv,
    required this.gustMph,
    required this.gustKph,
    required this.isDay,
    this.maxtempC,
    this.maxtempF,
    this.mintempC,
    this.mintempF,
    this.avgtempC,
    this.avgtempF,
  });

  @override
  List<Object?> get props => [
    tempC, tempF, condition, windMph, windKph, windDir, pressureMb,
    pressureIn, precipMm, precipIn, humidity, cloud, feelslikeC,
    feelslikeF, visKm, visMiles, uv, gustMph, gustKph, isDay, maxtempC,
    maxtempF, mintempC, mintempF, avgtempC, avgtempF
  ];

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      tempC: (json['temp_c'] ?? 0).toDouble(),
      tempF: (json['temp_f'] ?? 0).toDouble(),
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
      visKm: (json['vis_km'] ?? 0).toDouble(),
      visMiles: (json['vis_miles'] ?? 0).toDouble(),
      uv: (json['uv'] ?? 0).toDouble(),
      gustMph: (json['gust_mph'] ?? 0).toDouble(),
      gustKph: (json['gust_kph'] ?? 0).toDouble(),
      isDay: json['is_day'] ?? 1, // Default to day if not specified
      // Additional fields for forecast data
      maxtempC: json['maxtemp_c'] != null ? (json['maxtemp_c'] as num).toDouble() : null,
      maxtempF: json['maxtemp_f'] != null ? (json['maxtemp_f'] as num).toDouble() : null,
      mintempC: json['mintemp_c'] != null ? (json['mintemp_c'] as num).toDouble() : null,
      mintempF: json['mintemp_f'] != null ? (json['mintemp_f'] as num).toDouble() : null,
      avgtempC: json['avgtemp_c'] != null ? (json['avgtemp_c'] as num).toDouble() : null,
      avgtempF: json['avgtemp_f'] != null ? (json['avgtemp_f'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp_c': tempC,
      'temp_f': tempF,
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
      'vis_km': visKm,
      'vis_miles': visMiles,
      'uv': uv,
      'gust_mph': gustMph,
      'gust_kph': gustKph,
      'is_day': isDay,
      // Additional forecast fields
      'maxtemp_c': maxtempC,
      'maxtemp_f': maxtempF,
      'mintemp_c': mintempC,
      'mintemp_f': mintempF,
      'avgtemp_c': avgtempC,
      'avgtemp_f': avgtempF,
    };
  }
}

/// Location data model
class Location extends Equatable {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String tzId;
  final int localtimeEpoch;
  final String localtime;

  const Location({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.tzId,
    required this.localtimeEpoch,
    required this.localtime,
  });

  @override
  List<Object?> get props => [name, region, country, lat, lon, tzId, localtimeEpoch, localtime];

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      country: json['country'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      tzId: json['tz_id'] ?? '',
      localtimeEpoch: json['localtime_epoch'] ?? 0,
      localtime: json['localtime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'region': region,
      'country': country,
      'lat': lat,
      'lon': lon,
      'tz_id': tzId,
      'localtime_epoch': localtimeEpoch,
      'localtime': localtime,
    };
  }
}

/// Complete weather data model
class WeatherData extends Equatable {
  final Location location;
  final CurrentWeather current;

  const WeatherData({
    required this.location,
    required this.current,
  });

  @override
  List<Object?> get props => [location, current];

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: Location.fromJson(json['location'] ?? {}),
      current: CurrentWeather.fromJson(json['current'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'current': current.toJson(),
    };
  }
}