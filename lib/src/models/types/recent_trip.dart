import 'stop_area.dart';

class RecentTrip {
  List<StopArea> origins;
  List<StopArea> destinations;
  bool isFavorite;
  DateTime lastSearched = DateTime.now();

  RecentTrip(this.origins, this.destinations, [this.isFavorite = false]);
  RecentTrip.fromJson(Map<String, dynamic> json):
    origins = (json["origins"] as List).map((json) => StopArea.fromJson(json)).toList(),
    destinations = (json["destinations"] as List).map((json) => StopArea.fromJson(json)).toList(),
    isFavorite = json['isFavorite'],
    lastSearched = DateTime.parse(json['lastSearched']);

  Map<String, dynamic> toJson() => {
    'origins': origins.map((origin) => origin.toJson()).toList(),
    'destinations': destinations.map((destination) => destination.toJson()).toList(),
    'isFavorite': isFavorite,
    'lastSearched': lastSearched.toIso8601String(),
  };
}