import 'package:ai_enabled_restaurant_control_and_optimization/App/constant/color.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/dashboard/screen/homescreen.dart';
import 'package:ai_enabled_restaurant_control_and_optimization/dashboard/screen/onboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI-Enabled Restaurant Control and Optimization',
      theme: ThemeData(primaryColor: themeColor),
      home: const OnboardScreen(),
    );
  }
}
