class WishlistItem {
  final String id;
  final String userId;
  final String linkUrl;
  final String productName;
  final num? price;
  final String? currency;
  final String? imageUrl;
  final String? brand;
  final String? size;
  final DateTime createdAt;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.linkUrl,
    required this.productName,
    this.price,
    this.currency,
    this.imageUrl,
    this.brand,
    this.size,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      linkUrl: json['link_url'] as String,
      productName: json['product_name'] as String,
      price: json['price'] as num?,
      currency: json['currency'] as String?,
      imageUrl: json['image_url'] as String?,
      brand: json['brand'] as String?,
      size: json['size'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'link_url': linkUrl,
      'product_name': productName,
      'price': price,
      'currency': currency,
      'image_url': imageUrl,
      'brand': brand,
      'size': size,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
