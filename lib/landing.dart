import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home.dart';  // your home screen
import '../login.dart';  // your login screen

class LandingPage extends StatelessWidget {
  var userid = FirebaseAuth.instance.currentUser?.uid;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, show home page
        if (snapshot.hasData) {
          return HomeApp();
        } else {
          return Login();
        }
      },
    );
  }
}