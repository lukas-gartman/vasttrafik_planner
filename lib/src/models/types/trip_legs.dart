import 'journey_point.dart';

class TripLegs {
  JourneyPoint origin;
  JourneyPoint destination;
  List<JourneyPoint> stops;

  TripLegs(this.origin, this.destination, [this.stops = const []]);
}