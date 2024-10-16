import 'package:ai_enabled_restaurant_control_and_optimization/App/moods/moods_list_screen.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/App/screen/home/detail_screen.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/App/screen/order/order_screen.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/App/screen/table/table_reservation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../model/product_model.dart';
import '../../services/api_services.dart';
import '../chatbot/chat_screen.dart';
import '../splash/splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String fullName = '';
  String email = '';
  String profilePicture = '';
  String result = '';
  bool isLoading = false;

  void _showBottomSheet(BuildContext context, String itemName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: 300,
              child: Column(
                children: [
                  Text(
                    'Detail of $itemName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    Expanded(
                        flex: 7,
                        child: SingleChildScrollView(child: Text(result))),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        final content =
                            await ApiService.generateContent(itemName);
                        setState(() {
                          result = content;
                          isLoading = false;
                        });
                      } catch (e) {
                        setState(() {
                          result = 'Error fetching content.';
                          isLoading = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .where('Uid', isEqualTo: userId)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        setState(() {
          fullName = userData['Full Name'] ?? 'No Name';
          email = userData['Email'] ?? 'No Email';
          profilePicture = userData['Profile Url'] ?? '';
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Home Screen",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xff6149cd),
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : const AssetImage(
                              'assets/images/profile_placeholder.png')
                          as ImageProvider,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xff6149cd),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              ListTile(
                leading: const Icon(Icons.table_bar, color: Color(0xff6149cd)),
                title: const Text('Rserve Table'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (builder) => TableReservationScreen()));
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                leading:
                    const Icon(Icons.shopping_cart, color: Color(0xff6149cd)),
                title: const Text('Orders'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (builder) => OrdersPage()));
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                leading:
                const Icon(Icons.shopping_cart, color: Color(0xff6149cd)),
                title: const Text('Moods Food'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (builder) => MoodsListScreen()));
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xff6149cd)),
                  hintText: 'Search items...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('items').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error fetching data.'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No items found.'));
                  }

                  final items = snapshot.data!.docs.where((item) {
                    final title = item['title'].toString().toLowerCase();
                    final details = item['details'].toString().toLowerCase();

                    // Filter based on search query
                    return title.contains(searchQuery) ||
                        details.contains(searchQuery);
                  }).map((item) {
                    // Create a Product instance from the filtered data
                    return Product(
                      title: item['title'] ?? 'No title',
                      details: item['details'] ?? 'No details',
                      price: double.tryParse(item['price'].toString()) ?? 0.0,
                      productId: item['productId'] ?? 'No productId',
                      imageUrl: item['imageUrl'] ?? '',
                      mood: item['mood'] ?? '',
                      createdAt: DateTime.parse(item['createdAt'] ??
                          DateTime.now().toIso8601String()),
                    );
                  }).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final title = item.title;
                      final details = item.details;
                      final imageUrl = item.imageUrl;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                product: item,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Hero(
                                  tag: title,
                                  child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.redAccent,
                                            ),
                                          );
                                        },
                                      )),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xff333333),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      details,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xff777777),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          onPressed: () {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            _showBottomSheet(context, title);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
