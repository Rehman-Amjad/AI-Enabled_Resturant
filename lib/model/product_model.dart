class Product {
  final String title;
  final String details;
  final double price;
  final String productId;
  final String imageUrl;
  final String mood;
  final DateTime createdAt;

  Product({
    required this.title,
    required this.details,
    required this.price,
    required this.productId,
    required this.imageUrl,
    required this.createdAt,
    required this.mood,
  });

  // Factory method to create a Product from a Map (useful for converting JSON to a Product)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      title: map['title'] ?? '',
      details: map['details'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      productId: map['productId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      mood: map['mood'] ?? '',
      createdAt:
          DateTime.parse(map['createdAt']), // Parsing from string to DateTime
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'details': details,
      'price': price,
      'productId': productId,
      'imageUrl': imageUrl,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(), // Converting DateTime to string
    };
  }
}
