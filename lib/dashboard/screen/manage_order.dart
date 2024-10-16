import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html; // For file download in Flutter Web
import 'dart:typed_data';

import '../../model/buy_product_model.dart'; // For handling binary data

class AdminOrdersPage extends StatefulWidget {
  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String? selectedStatus;
  final List<String> statuses = [
    'Pending',
    'Preparing',
    'Ready to Serve',
    'Served'
  ];
  double totalRevenueThisMonth = 0.0;
  double totalRevenueOnwards = 0.0;

  @override
  void initState() {
    super.initState();
    calculateTotalRevenue();
  }

  void calculateTotalRevenue() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('revenue')
        .where('status', isNotEqualTo: 'Completed')
        .get();

    double monthRevenue = 0.0;
    double onwardRevenue = 0.0;

    for (var doc in querySnapshot.docs) {
      final order = BuyProduct.fromMap(doc.data() as Map<String, dynamic>);
      if (order.dateTime.isAfter(firstDayOfMonth)) {
        monthRevenue += order.product.price;
      }
      onwardRevenue += order.product.price;
    }

    setState(() {
      totalRevenueThisMonth = monthRevenue;
      totalRevenueOnwards = onwardRevenue;
    });
  }

  Stream<List<BuyProduct>> fetchOrders() {
    Query query = FirebaseFirestore.instance
        .collection('revenue')
        .where('status', isNotEqualTo: 'Completed');

    if (selectedStatus != null) {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BuyProduct.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('revenue')
        .doc(orderId)
        .update({'status': newStatus});
    calculateTotalRevenue(); // Recalculate revenue after status change
  }

  Future<void> downloadReceipt(BuyProduct order) async {
    // For simplicity, we're using plain text as the receipt format.
    final content = '''
      Receipt for Order ${order.buyId}
      Product: ${order.product.title}
      Details: ${order.product.details}
      Price: \$${order.product.price.toStringAsFixed(2)}
      Date: ${DateFormat.yMMMd().format(order.dateTime)}
      Status: ${order.status}
    ''';

    final bytes = Uint8List.fromList(content.codeUnits);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "receipt_${order.buyId}.txt")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Orders'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Revenue This Month: \$${totalRevenueThisMonth.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Total Revenue Onwards: \$${totalRevenueOnwards.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedStatus,
              hint: Text('Filter by Status'),
              items: statuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<BuyProduct>>(
                stream: fetchOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No orders available'));
                  }

                  List<BuyProduct> orders = snapshot.data!;

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      BuyProduct order = orders[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(order.product.imageUrl),
                            radius: 30,
                          ),
                          title: Text(order.product.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${order.status}'),
                              DropdownButton<String>(
                                value: order.status,
                                items: statuses.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && value != order.status) {
                                    updateOrderStatus(order.buyId, value);
                                  }
                                },
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () => downloadReceipt(order),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
