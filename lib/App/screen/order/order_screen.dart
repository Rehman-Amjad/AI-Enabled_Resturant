import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../model/buy_product_model.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> statuses = [
    'Pending',
    'Preparing',
    'Ready to Serve',
    'Served'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);
  }

  Stream<List<BuyProduct>> fetchOrdersByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('revenue')
        .where('status', isEqualTo: status)
        .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => BuyProduct.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('Orders'),
        bottom: TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: statuses.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: statuses.map((status) {
          return StreamBuilder<List<BuyProduct>>(
            stream: fetchOrdersByStatus(status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child:
                      CircularProgressIndicator(), // Custom loading indicator
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text('No orders for $status'),
                    ],
                  ),
                );
              }

              List<BuyProduct> orders = snapshot.data!;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  BuyProduct order = orders[index];
                  return SlideAnimation(
                    child: Slidable(
                      key: Key(order.buyId),
                      endActionPane: ActionPane(
                        motion: ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              // Action to mark as complete
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Marked as Complete'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            icon: Icons.check,
                            label: 'Complete',
                          ),
                          SlidableAction(
                            onPressed: (context) {
                              // Action to delete
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order Deleted'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(order.product.imageUrl),
                          radius: 30,
                        ),
                        title: Text(order.product.title),
                        subtitle: Text('Status: ${order.status}'),
                        trailing:
                            Text('\$${order.product.price.toStringAsFixed(2)}'),
                        onTap: () {},
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class SlideAnimation extends StatelessWidget {
  final Widget child;

  const SlideAnimation({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: child,
      builder: (context, Offset offset, child) {
        return Transform.translate(offset: offset, child: child);
      },
    );
  }
}
