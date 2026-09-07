import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

enum LiveWeatherKind { clear, cloudy, rain, snow }

class WeatherContextData {
  const WeatherContextData({
    required this.kind,
    required this.rainySpell,
    required this.fromLiveData,
    this.latitude,
    this.longitude,
  });

  final LiveWeatherKind kind;
  final bool rainySpell;
  final bool fromLiveData;
  final double? latitude;
  final double? longitude;

  static const fallback = WeatherContextData(
    kind: LiveWeatherKind.clear,
    rainySpell: false,
    fromLiveData: false,
  );
}

class WeatherContextService {
  static Future<WeatherContextData>? _cachedLoad;

  static Future<WeatherContextData> load() {
    return _cachedLoad ??= _loadOnce();
  }

  static Future<WeatherContextData> _loadOnce() async {
    try {
      final position = await _currentPosition();
      if (position == null) return WeatherContextData.fallback;

      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': position.latitude.toStringAsFixed(4),
        'longitude': position.longitude.toStringAsFixed(4),
        'current': 'weather_code,precipitation,rain,snowfall,cloud_cover',
        'daily':
            'precipitation_sum,rain_sum,snowfall_sum,precipitation_hours,precipitation_probability_max,temperature_2m_mean',
        'past_days': '3',
        'forecast_days': '5',
        'timezone': 'auto',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return WeatherContextData.fallback;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return WeatherContextData.fallback;

      final current = decoded['current'];
      final daily = decoded['daily'];
      final kind = current is Map<String, dynamic>
          ? _weatherKind(current)
          : LiveWeatherKind.clear;
      final rainySpell = daily is Map<String, dynamic>
          ? detectRainySpell(daily)
          : false;

      return WeatherContextData(
        kind: kind,
        rainySpell: rainySpell && kind != LiveWeatherKind.snow,
        fromLiveData: true,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      debugPrint('Open-Meteo weather unavailable: $error');
      return WeatherContextData.fallback;
    }
  }

  static Future<Position?> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final settings = LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 7),
      );
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  static LiveWeatherKind _weatherKind(Map<String, dynamic> current) {
    final snowfall = (current['snowfall'] as num?)?.toDouble() ?? 0;
    final rain = (current['rain'] as num?)?.toDouble() ?? 0;
    final precipitation = (current['precipitation'] as num?)?.toDouble() ?? 0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;

    if (snowfall > 0 || _isSnowCode(code)) return LiveWeatherKind.snow;
    if (rain > 0 || precipitation > .1 || _isRainCode(code)) {
      return LiveWeatherKind.rain;
    }
    if (code == 0 || code == 1) return LiveWeatherKind.clear;
    return LiveWeatherKind.cloudy;
  }

  static bool _isRainCode(int code) =>
      (code >= 51 && code <= 67) ||
      (code >= 80 && code <= 82) ||
      (code >= 95 && code <= 99);

  static bool _isSnowCode(int code) =>
      (code >= 71 && code <= 77) || (code >= 85 && code <= 86);
}

bool detectRainySpell(Map<String, dynamic> daily) {
  final precipitation = _numList(daily['precipitation_sum']);
  final rain = _numList(daily['rain_sum']);
  final snow = _numList(daily['snowfall_sum']);
  final hours = _numList(daily['precipitation_hours']);
  final probabilities = _numList(daily['precipitation_probability_max']);
  final temperatures = _numList(daily['temperature_2m_mean']);

  if (precipitation.isEmpty) return false;

  final length = precipitation.length;
  var wetDays = 0;
  var totalPrecipitation = 0.0;
  var totalRain = 0.0;
  var totalSnow = 0.0;
  var totalHours = 0.0;
  var warmSamples = 0;
  var warmSum = 0.0;

  for (var i = 0; i < length; i++) {
    final p = precipitation[i];
    final h = i < hours.length ? hours[i] : 0.0;
    final probability = i < probabilities.length ? probabilities[i] : 0.0;
    if (p >= 3 || h >= 4 || probability >= 70) wetDays++;
    totalPrecipitation += p;
    if (i < rain.length) totalRain += rain[i];
    if (i < snow.length) totalSnow += snow[i];
    totalHours += h;
    if (i < temperatures.length) {
      warmSum += temperatures[i];
      warmSamples++;
    }
  }

  final meanTemperature = warmSamples == 0 ? 20.0 : warmSum / warmSamples;
  final warmEnough = meanTemperature >= 18;
  final rainDominant = totalRain >= totalSnow * 3;

  return warmEnough &&
      rainDominant &&
      wetDays >= 4 &&
      totalPrecipitation >= 25 &&
      totalHours >= 18;
}

List<double> _numList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((value) => (value as num?)?.toDouble() ?? 0).toList();
}

class WeatherContextBuilder extends StatefulWidget {
  const WeatherContextBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, WeatherContextData data) builder;

  @override
  State<WeatherContextBuilder> createState() => _WeatherContextBuilderState();
}

class _WeatherContextBuilderState extends State<WeatherContextBuilder> {
  WeatherContextData _data = WeatherContextData.fallback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await WeatherContextService.load();
    if (!mounted) return;
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _data);
}
