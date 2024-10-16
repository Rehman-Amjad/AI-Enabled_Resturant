import 'package:ai_enabled_restaurant_control_and_optimization/model/product_model.dart';

import 'package:firebase_auth/firebase_auth.dart';

class BuyProduct {
  final String buyId;
  final String productId;
  final String userId;
  final Product product;
  final DateTime dateTime;
  final String status;

  BuyProduct({
    required this.buyId,
    required this.productId,
    String? userId,
    required this.product,
    DateTime? dateTime,
    this.status = 'Pending',
  })  : userId = userId ?? FirebaseAuth.instance.currentUser!.uid,
        dateTime = dateTime ?? DateTime.now();

  factory BuyProduct.fromMap(Map<String, dynamic> map) {
    return BuyProduct(
      buyId: map['buyId'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      product: Product.fromMap(map['product']),
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyId': buyId,
      'productId': productId,
      'userId': userId,
      'product': product.toMap(),
      'dateTime': dateTime.toIso8601String(),
      'status': status,
    };
  }
}
