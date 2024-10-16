import 'package:ai_enabled_restaurant_control_and_optimization/App/screen/chatbot/chat_screen.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/App/widget/button/simple_button.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/model/buy_product_model.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/model/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final Product product;
  const DetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    bool loading = false;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        centerTitle: true,
        backgroundColor: const Color(0xff6149cd),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (builder) => ChatScreen(
                              title: product.title,
                            )));
              },
              icon: const Icon(
                Icons.info,
                color: Colors.white,
              ))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Hero(
              tag: product.title, // Unique tag for the Hero animation
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * 0.60,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                product.details,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SimpleButton(
                  color: Colors.purple,
                  onTap: () async {
                    try {
                      loading = true;
                      final String buyId =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      final buyProduct = BuyProduct(
                        buyId: buyId,
                        productId: product.productId,
                        product: product,
                      );
                      await FirebaseFirestore.instance
                          .collection("revenue")
                          .doc(buyId)
                          .set(buyProduct.toMap());
                    } finally {
                      loading = false;
                    }
                  },
                  title: "Buy"),
            )
          ],
        ),
      ),
    );
  }
}
