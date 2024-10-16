import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../model/product_model.dart';
import '../screen/home/detail_screen.dart';
import '../services/api_services.dart';

class MoodsListScreen extends StatefulWidget {
  MoodsListScreen({super.key});

  @override
  State<MoodsListScreen> createState() => _MoodsListScreenState();
}

class _MoodsListScreenState extends State<MoodsListScreen> {
  final moodsList = [
    {"name": "Happy"},
    {"name": "Sad"},
    {"name": "Angry"},
    {"name": "Blessed"},
    {"name": "Normal"},
    {"name": "Cry"},
  ];


  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Select Your Mood"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of items in each row
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: moodsList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoodDetailScreen(
                      moodName: moodsList[index]['name']!,
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    moodsList[index]['name']!,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MoodDetailScreen extends StatefulWidget {
  final String moodName;

  const MoodDetailScreen({super.key, required this.moodName});

  @override
  State<MoodDetailScreen> createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends State<MoodDetailScreen> {
  bool isLoading = false;
  String result = '';
  String searchQuery = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mood Details"),
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
              FirebaseFirestore.instance.collection('items')
                  .where("mood", isEqualTo: widget.moodName)
                  .snapshots(),
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
                  shrinkWrap: true,
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
    );
  }
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

}


