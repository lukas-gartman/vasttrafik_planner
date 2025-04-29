import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'types/coordinate.dart';

class LocationHandler {
  late Position _currentPos;
  late StreamSubscription<Position>? _posStreamSub;
  late Function _onLocationUpdate;
  int _updateDistance = 5;

  Position get currentPos => _currentPos;
  void setUpdateDistance(int distance) => _updateDistance = distance;

  static Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  void startStream(Function onLocationUpdate) async {
    if (!await checkPermission()) { throw Exception("Location permission not granted"); }

    _onLocationUpdate = onLocationUpdate;
    LocationSettings settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: _updateDistance);
    _posStreamSub = Geolocator.getPositionStream(locationSettings: settings).listen((Position pos) {
      _currentPos = pos;
      _onLocationUpdate();
    });
  }

  void stopStream() {
    _posStreamSub?.cancel();
    _posStreamSub = null;
  }
  

  static Future<Position> getCurrentPosition() async {
    if (!await checkPermission()) { throw Exception("Location permission not granted"); }

    return await Geolocator.getCurrentPosition();
  }

  double calculateDistanceTo(Coordinate coord) {
    return Coordinate.calculateDistance(Coordinate(_currentPos.latitude, _currentPos.longitude), coord);
  }
}