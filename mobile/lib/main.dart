import 'package:flutter/material.dart';
import 'package:mobile/screens/login_screen.dart';

void main() {
  runApp(const ClubApp());
}

class ClubApp extends StatelessWidget {
  const ClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club Ezequiel Spagnoli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const LoginScreen(),
    );
  }
}
