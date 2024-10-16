import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  void addMessage(String message, bool isUser) {
    _messages.add(Message(message, isUser));
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    _isLoading = true;
    notifyListeners();

    addMessage(message, true);

    try {
      final response = await ApiService.generateContent(message);
      addMessage(response, false);
      scrollToBottom();
    } catch (e) {
      addMessage('Failed to get response', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final ScrollController scrollController = ScrollController();

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
