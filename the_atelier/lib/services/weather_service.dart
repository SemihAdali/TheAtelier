import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherForecast {
  final String temperature;
  final String description;

  WeatherForecast({required this.temperature, required this.description});
}

class WeatherService {
  /// Fetches a 16-day forecast from OpenMeteo and attempts to find matching weather for dates.
  /// If dates are outside the 16 day window, falls back to the current/generic forecast.
  Future<WeatherForecast?> fetchWeatherForTrip(
      double lat, double lon, DateTime startDate, DateTime endDate) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_max,weathercode&timezone=auto&forecast_days=16');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final daily = data['daily'] as Map<String, dynamic>;
        final times = List<String>.from(daily['time']);
        final temps = List<double>.from(daily['temperature_2m_max']);
        final codes = List<int>.from(daily['weathercode']);

        // Format trip start date to YYYY-MM-DD
        final startIso = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
        
        int matchIndex = times.indexOf(startIso);
        
        // If start date is out of the 16-day range, just take the 14th day as a rough estimate
        if (matchIndex == -1) {
          matchIndex = times.length > 14 ? 14 : 0;
        }

        if (times.isNotEmpty) {
          final tempC = temps[matchIndex];
          final weatherCode = codes[matchIndex];
          final desc = _mapWeatherCode(weatherCode);

          return WeatherForecast(
            temperature: '${tempC.round()}°C',
            description: desc,
          );
        }
      }
    } catch (e) {
      print('OpenMeteo API Error: $e');
    }
    return null;
  }

  /// Extremely simplified WMO Weather Code to String mapper
  String _mapWeatherCode(int code) {
    if (code == 0) return 'CLEAR SKY';
    if (code == 1 || code == 2 || code == 3) return 'PARTLY CLOUDY';
    if (code >= 45 && code <= 48) return 'FOGGY';
    if (code >= 51 && code <= 67) return 'RAINY';
    if (code >= 71 && code <= 77) return 'SNOWING';
    if (code >= 80 && code <= 82) return 'HEAVY RAIN';
    if (code >= 95) return 'THUNDERSTORM';
    return 'CLOUDY';
  }
}
