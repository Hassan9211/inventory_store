import 'package:flutter/material.dart';
import 'package:inventory_store/screens/signup_screen';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SignUpPage());
  }
}
