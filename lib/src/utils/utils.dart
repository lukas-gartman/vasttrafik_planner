import 'package:flutter/material.dart';
import '../models/types/journey_point.dart';
import '../models/types/line.dart';

enum SearchSelection { from, to, none }

Color hexToColor(String hex) => Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);

String formatTime(DateTime time) {
  time = time.toLocal();
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
}

bool isOnTime(JourneyPoint point) => point.plannedTime == point.estimatedTime;

Container createLineBadge(Line line) {
  return Container(
    width: 35.0,
    height: 25.0,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: hexToColor(line.backgroundColor),
      border: Border.all(color: hexToColor(line.borderColor)),
      borderRadius: BorderRadius.circular(4.0),
    ),
    child: Text(
      line.name,
      style: TextStyle(
        color: hexToColor(line.foregroundColor),
        fontSize: line.name.length > 3 ? 10.0 : 14.0,
      ),
    ),
  );
}