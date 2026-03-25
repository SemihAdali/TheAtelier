class Outfit {
  final String id;
  String name;
  String? occasion;
  List<String> items;          // WardrobeItem IDs
  List<String> wishlistItems;  // WishlistItem IDs
  String? imageUrl;
  final DateTime createdAt;

  Outfit({
    required this.id,
    required this.name,
    this.occasion,
    this.items = const [],
    this.wishlistItems = const [],
    this.imageUrl,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as String,
      name: json['name'] as String,
      occasion: json['occasion'] as String?,
      items: json['items'] != null ? List<String>.from(json['items']) : [],
      wishlistItems: json['wishlist_items'] != null ? List<String>.from(json['wishlist_items']) : [],
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion,
      'items': items,
      'wishlist_items': wishlistItems,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Total number of pieces in this outfit
  int get totalPieces => items.length + wishlistItems.length;
}

// Local cache for Outfits
List<Outfit> mockOutfits = [];
