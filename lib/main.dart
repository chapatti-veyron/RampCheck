import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const RampCheckApp());
}

class RampCheckApp extends StatefulWidget {
  const RampCheckApp({super.key});

  @override
  State<RampCheckApp> createState() => _RampCheckAppState();
}

class _RampCheckAppState extends State<RampCheckApp> {
  bool isLoggedIn = false;

  void onLoginSuccess() {
    setState(() {
      isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RampCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.grey
      ),
      home: isLoggedIn
          ? const HomeScreen()
          : LoginScreen(onLoginSuccess: onLoginSuccess)
    );
  }
}
