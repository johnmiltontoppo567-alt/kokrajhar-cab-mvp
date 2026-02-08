import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class CabApp extends StatelessWidget {
  const CabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kokrajhar Cab',
      theme: ThemeData(
        primarySwatch: Colors.yellow, // Classic cab colors
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}