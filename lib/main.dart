import 'package:flutter/material.dart';
import 'package:vasttrafik_planner/src/views/trips_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Västtrafik Planner 2.0',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade900, brightness: Brightness.light), useMaterial3: true),
      home: const TripsPage(),
    );
  }
}
