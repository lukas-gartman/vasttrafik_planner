import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_handler.dart';
import '../models/types/coordinate.dart';

class LocationController {
  final LocationHandler _locationHandler = LocationHandler();
  late final Function _onLocationUpdate;

  Position get currentPos => _locationHandler.currentPos;
  LatLng get currentLatLng => LatLng(currentPos.latitude, currentPos.longitude);

  void setOnLocationUpdate(Function listener) => _onLocationUpdate = listener;

  void startListening() {
    _locationHandler.startStream(_onLocationUpdate);
  }

  void stopListening() {
    _locationHandler.stopStream();
  }
  
  double getDistanceTo(Coordinate coord) {
    return _locationHandler.calculateDistanceTo(coord);
  }

  LatLng toLatLng(Coordinate coord) => LatLng(coord.latitude, coord.longitude);
}