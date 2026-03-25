import 'dart:convert';

class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? weatherTemp;
  final String? weatherDescription;
  final String? purpose;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<PackingItem> packingList;
  final List<String> savedOutfitIds;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.weatherTemp,
    this.weatherDescription,
    this.purpose,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.packingList = const [],
    this.savedOutfitIds = const [],
  });

  Trip copyWith({
    String? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? weatherTemp,
    String? weatherDescription,
    String? purpose,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<PackingItem>? packingList,
    List<String>? savedOutfitIds,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weatherTemp: weatherTemp ?? this.weatherTemp,
      weatherDescription: weatherDescription ?? this.weatherDescription,
      purpose: purpose ?? this.purpose,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      packingList: packingList ?? this.packingList,
      savedOutfitIds: savedOutfitIds ?? this.savedOutfitIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'weatherTemp': weatherTemp,
      'weatherDescription': weatherDescription,
      'purpose': purpose,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'packingList': packingList.map((x) => x.toMap()).toList(),
      'savedOutfitIds': savedOutfitIds,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      destination: map['destination'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      weatherTemp: map['weatherTemp'],
      weatherDescription: map['weatherDescription'],
      purpose: map['purpose'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      imageUrl: map['imageUrl'],
      packingList: List<PackingItem>.from(
        map['packingList']?.map((x) => PackingItem.fromMap(x)) ?? [],
      ),
      savedOutfitIds: List<String>.from(map['savedOutfitIds'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory Trip.fromJson(String source) => Trip.fromMap(json.decode(source));
}

class PackingItem {
  final String id;
  final String name;
  final String category;
  final bool isPacked;
  final bool isAIRecommended;
  final String? imageUrl;

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    this.isPacked = false,
    this.isAIRecommended = false,
    this.imageUrl,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? isPacked,
    bool? isAIRecommended,
    String? imageUrl,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isPacked: isPacked ?? this.isPacked,
      isAIRecommended: isAIRecommended ?? this.isAIRecommended,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isPacked': isPacked,
      'isAIRecommended': isAIRecommended,
      'imageUrl': imageUrl,
    };
  }

  factory PackingItem.fromMap(Map<String, dynamic> map) {
    return PackingItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      isPacked: map['isPacked'] ?? false,
      isAIRecommended: map['isAIRecommended'] ?? false,
      imageUrl: map['imageUrl'],
    );
  }
}
