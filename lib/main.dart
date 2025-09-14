import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:timetabel/landing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
  assert(() { 
    debugPrint('Debug banner is disabled.');
    return true;
  }());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LandingPage(),
    );
  }
}
