import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' as foundation; // Import for detecting platform
import '../../model/product_model.dart';
import '../widget/custom_text_field.dart';

class AddItemScreen extends StatefulWidget {
  final bool isEdit;
  final String? itemId;

  const AddItemScreen({super.key, required this.isEdit, this.itemId});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _imagePath;
  Uint8List? _imageBytes; // For storing image bytes on web
  String? _imageUrl;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Modified function to handle both web and mobile platforms
  void _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      final file = result.files.first;

      setState(() {
        if (foundation.kIsWeb) {
          // For web, use bytes
          _imageBytes = file.bytes;
        } else {
          // For mobile, use path
          _imagePath = file.path;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.itemId != null) {
      _loadItemData();
    }
  }

  void _loadItemData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _titleController.text = data['title'] ?? '';
            _detailController.text = data['details'] ?? '';
            _priceController.text = data['price']?.toString() ?? '';
            _imageUrl = data['imageUrl'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading item data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImage() async {
    try {
      String fileName;
      UploadTask uploadTask;

      if (foundation.kIsWeb) {
        // For web, use bytes
        fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef =
        FirebaseStorage.instance.ref().child('items_images/$fileName');
        uploadTask = storageRef.putData(_imageBytes!);
      } else {
        // For mobile, use path
        final imageFile = File(_imagePath!);
        fileName = path.basename(imageFile.path);
        final storageRef =
        FirebaseStorage.instance.ref().child('items_images/$fileName');
        uploadTask = storageRef.putFile(imageFile);
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading image: $e';
      });
      return null;
    }
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      String? imageUrl;
      if (_imagePath != null || _imageBytes != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        imageUrl = _imageUrl;
      }

      try {
        final String productId =
        DateTime.now().millisecondsSinceEpoch.toString();
        if (widget.isEdit && widget.itemId != null) {
          await FirebaseFirestore.instance
              .collection('items')
              .doc(widget.itemId)
              .update({
            'title': _titleController.text,
            'details': _detailController.text,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'imageUrl': imageUrl,
          });
        } else {
          Product product = Product(
            title: _titleController.text,
            details: _detailController.text,
            price: double.tryParse(_priceController.text) ?? 0.0,
            productId: productId,
            imageUrl: imageUrl!,
            mood: "",
            createdAt: DateTime.now(), // Set the current date and time
          );

          await FirebaseFirestore.instance
              .collection('items')
              .add(product.toMap());
        }
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = 'Error saving item: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Item' : 'Add Item'),
        centerTitle: true,
        backgroundColor: const Color(0xff6149cd),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  CustomTextField(
                    title: 'Title',
                    hint: 'Enter item title',
                    controller: _titleController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    title: 'Details',
                    hint: 'Enter item details',
                    controller: _detailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter item details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    title: 'Price',
                    hint: 'Enter item price',
                    controller: _priceController,
                    inputType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter item price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xfff0f0f0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xff6149cd), width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              size: 40,
                              color: Color(0xff6149cd),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to Pick Image',
                              style: TextStyle(
                                color: Color(0xff6149cd),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_imagePath != null)
                    Image.file(
                      File(_imagePath!),
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  else if (_imageBytes != null) // For web, display image from bytes
                    Image.memory(
                      _imageBytes!,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  else if (_imageUrl != null)
                      Image.network(
                        _imageUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6149cd),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Save Item'),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
