import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/outfit.dart';
import '../models/trip.dart';

class StorageService {
  static const String _outfitsKey = 'saved_outfits';
  static const String _tripsKey = 'saved_trips';

  final SharedPreferences _prefs;

  static late final StorageService instance;

  StorageService._(this._prefs);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance = StorageService._(prefs);
  }

  // --- Outfits ---

  Future<void> saveOutfits(List<Outfit> outfits) async {
    final jsonList = outfits.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList(_outfitsKey, jsonList);
  }

  List<Outfit> getOutfits() {
    final jsonList = _prefs.getStringList(_outfitsKey);
    if (jsonList == null) return [];
    
    return jsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Outfit.fromJson(map);
    }).toList();
  }
  
  Future<void> addOutfit(Outfit outfit) async {
    final current = getOutfits();
    current.insert(0, outfit);
    await saveOutfits(current);
  }

  // --- Trips ---

  Future<void> saveTrips(List<Trip> trips) async {
    final jsonList = trips.map((t) => jsonEncode(t.toMap())).toList();
    await _prefs.setStringList(_tripsKey, jsonList);
  }

  List<Trip> getTrips() {
    final jsonList = _prefs.getStringList(_tripsKey);
    if (jsonList == null) return [];

    return jsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Trip.fromMap(map);
    }).toList();
  }
  
  Future<void> addTrip(Trip trip) async {
    final current = getTrips();
    current.insert(0, trip);
    await saveTrips(current);
  }

  Future<void> deleteTrip(String id) async {
    final trips = getTrips();
    trips.removeWhere((t) => t.id == id);
    await saveTrips(trips);
  }
}
