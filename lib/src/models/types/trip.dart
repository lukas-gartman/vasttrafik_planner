import 'service_journey.dart';
import 'trip_legs.dart';

class Trip {
  ServiceJourney serviceJourney;
  TripLegs tripLegs;
  bool isCancelled;
  bool isPartCancelled;

  Trip(this.serviceJourney, this.tripLegs, this.isCancelled, this.isPartCancelled);
}