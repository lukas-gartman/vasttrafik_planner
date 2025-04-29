import 'trip.dart';

class Journey {
  List<Trip> trips;
  String? reconstructionReference;
  String? detailsReference;

  Journey(this.trips, [this.reconstructionReference, this.detailsReference]);
}