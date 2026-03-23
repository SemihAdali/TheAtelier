class WardrobeItem {
  final String id;
  String name;
  String category;
  String? color;
  String? brand;
  String? size;
  List<String> tags;
  String imageUrl;
  final DateTime createdAt;

  WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    this.color,
    this.brand,
    this.size,
    this.tags = const [],
    required this.imageUrl,
    required this.createdAt,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      color: json['color'] as String?,
      brand: json['brand'] as String?,
      size: json['size'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'brand': brand,
      'size': size,
      'tags': tags,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Keeping this list as a local cache or for initial load (optional)
List<WardrobeItem> mockWardrobe = [];
