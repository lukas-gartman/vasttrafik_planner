import 'package:flutter/material.dart';

import 'trip_display_strategy.dart';
import '../controllers/location_controller.dart';
import '../models/types/stop_area.dart';

class StopSearchResultDisplayStrategy extends TripDisplayStrategy<StopArea> {
  LocationController? locationController;
  
  StopSearchResultDisplayStrategy(super.data, super.onClick, [this.locationController]) {
    if (locationController != null) {
      locationController = locationController;
    }

    _setup();
  }

  void _setup() {
    if (locationController != null) {
      locationController!.startListening();
    }
  }

  String _getDistanceLabel(double distance) {
    if (distance < 1000) {
      return "${distance.toStringAsFixed(0)} m";
    } else {
      return "${(distance / 1000).toStringAsFixed(1)} km";
    }
  }

  @override
  Widget buildWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (StopArea stop in data)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton(
              onPressed: () => onClick(stop),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(stop.name),
                  if (locationController != null)
                    Text(_getDistanceLabel(locationController!.getDistanceTo(stop.coord))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}