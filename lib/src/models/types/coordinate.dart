import 'dart:math' as math;

class Coordinate {
  double latitude;
  double longitude;

  Coordinate(this.latitude, this.longitude);
  Coordinate.fromJson(Map<String, dynamic> json) : latitude = json["latitude"] ?? 0.0, longitude = json["longitude"] ?? 0.0;
  Map<String, dynamic> toJson() => { "latitude": latitude, "longitude": longitude };
  static double calculateDistance(Coordinate c1, Coordinate c2) {
    const R = 6371000; // Earth's radius in meters

    double lat1Rad = (c1.latitude * math.pi) / 180;
    double lat2Rad = (c2.latitude * math.pi) / 180;
    double lon1Rad = (c1.longitude * math.pi) / 180;
    double lon2Rad = (c2.longitude * math.pi) / 180;

    double dlat = lat2Rad - lat1Rad;
    double dlon = lon2Rad - lon1Rad;

    double a = math.sin(dlat / 2) * math.sin(dlat / 2) + math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(dlon / 2) * math.sin(dlon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    double distance = R * c;
    return distance;
  }
}