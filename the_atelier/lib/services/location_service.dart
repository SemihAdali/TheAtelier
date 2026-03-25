import 'dart:convert';
import 'package:http/http.dart' as http;

class CityLocation {
  final String displayName;
  final double latitude;
  final double longitude;

  CityLocation({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static const String _userAgent = 'TheAtelierTravelPlanner/1.0';

  /// Fetches an autocomplete list from OpenStreetMap Nominatim API.
  Future<List<CityLocation>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');

    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return CityLocation(
            displayName: json['display_name'] ?? 'Unknown location',
            latitude: double.tryParse(json['lat'].toString()) ?? 0.0,
            longitude: double.tryParse(json['lon'].toString()) ?? 0.0,
          );
        }).toList();
      }
    } catch (e) {
      print('Nominatim API Error: $e');
    }
    return [];
  }
}
