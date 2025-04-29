import 'package:flutter/material.dart';

import 'trip_display_strategy.dart';
import '../models/types/journey_point.dart';
import '../models/types/line.dart';
import '../models/types/journey.dart';
import '../utils/utils.dart';

class JourneySearchResultDisplayStrategy extends TripDisplayStrategy<Journey> {
  JourneySearchResultDisplayStrategy(super.data, super.onClick);

  @override
  Widget buildWidget(BuildContext context) {
    Row createTimeRow(JourneyPoint origin, JourneyPoint destination) {
      bool isOnTime(JourneyPoint point) => point.plannedTime == point.estimatedTime;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isOnTime(origin)
          ? Column(children: [
            Text(formatTime(origin.plannedTime), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!isOnTime(destination)) const Text(""),
          ],)
          : Column(children: [
            Text(formatTime(origin.estimatedTime), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(formatTime(origin.plannedTime), style: const TextStyle(decoration: TextDecoration.lineThrough)),
          ],),
          
          const Text(" - "),

          isOnTime(destination)
          ? Column(children: [
            Text(formatTime(destination.plannedTime), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!isOnTime(origin)) const Text(""),
          ],)
          : Column(children: [
            Text(formatTime(destination.estimatedTime), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(formatTime(destination.plannedTime), style: const TextStyle(decoration: TextDecoration.lineThrough)),
          ],),
        ]
      );
    }

    String createTimeLabel(JourneyPoint origin, JourneyPoint destination) {
      final int travelTime = destination.plannedTime.difference(origin.plannedTime).inMinutes;
      if (travelTime < 60) { return "$travelTime min"; }
      else if (travelTime == 60) { return "1 hr"; }
      else { return "${travelTime ~/ 60} hrs ${travelTime % 60} min"; }
    }

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

    Expanded createLineTravelIndicator(Color color, int flexWidth, [bool noTick = false]) {
      double tickHeight = 12.0;
      return Expanded(
        flex: flexWidth,
        child: SizedBox(
          height: tickHeight,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                height: 5.0,
                decoration: BoxDecoration(color: color),
              ),
              Positioned( 
                right: 0.0,
                bottom: 0.0,
                child: Container(width: noTick ? 0.0 : 5.0, height: tickHeight, color: color),
              ),
            ],
          ),
        )
      );
    }
    
    int calcFlexWidth(DateTime startTime, DateTime endTime) {
      double maxTripDuration = data
        .expand((journey) => journey.trips)
        .map((trip) => trip.tripLegs.destination.plannedTime.difference(trip.tripLegs.origin.plannedTime).inMinutes)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

      int width = (endTime.difference(startTime).inMinutes / maxTripDuration * 100).toInt();
      return width < 1 ? 1 : width;
    }
    
    return ListView(
      children: <Widget>[
        for (Journey journey in data)
          TextButton(
            onPressed: () => onClick(journey),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: [
                    Text(journey.trips[0].tripLegs.origin.stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(" Platform ${journey.trips[0].tripLegs.origin.platform}")
                  ]),
                  createTimeRow(journey.trips[0].tripLegs.origin, journey.trips.last.tripLegs.destination),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Travel time: ${createTimeLabel(journey.trips[0].tripLegs.origin, journey.trips.last.tripLegs.destination)}", style: const TextStyle(fontSize: 12.0)),
                ]
              ),
              Row(
                children: [
                  for (var i = 0; i < journey.trips.length; i++) ...[
                    createLineBadge(journey.trips[i].serviceJourney.line),
                    createLineTravelIndicator(hexToColor(journey.trips[i].serviceJourney.line.backgroundColor), calcFlexWidth(journey.trips[i].tripLegs.origin.plannedTime, journey.trips[i].tripLegs.destination.plannedTime)),
                    if (i < journey.trips.length - 1)
                      createLineTravelIndicator(Colors.grey, calcFlexWidth(journey.trips[i].tripLegs.destination.plannedTime, journey.trips[i+1].tripLegs.origin.plannedTime), true),
                  ],
                ]
              ),
            ])
          ),
      ],
    );
  } 
}