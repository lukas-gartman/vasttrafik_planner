import 'stop_area.dart';

class JourneyPoint {
  StopArea stop;
  String platform;
  DateTime plannedTime;
  DateTime estimatedTime;
  // List<String> notes;

  JourneyPoint(this.stop, this.platform, this.plannedTime, this.estimatedTime);

  JourneyPoint.fromJson(Map<String, dynamic> json):
    stop = StopArea.fromJson(json["stopPoint"]["stopArea"]),
    platform = json["stopPoint"]["platform"],
    plannedTime = DateTime.parse(json["plannedTime"] ?? json["plannedDepartureTime"] ?? json["plannedArrivalTime"]),
    estimatedTime = DateTime.parse(json["estimatedOtherwisePlannedTime"] ?? json["estimatedOtherwisePlannedDepartureTime"] ?? json["estimatedOtherwisePlannedArrivalTime"]);

  Map<String, dynamic> toJson() => {
    "stop": stop.toJson(),
    "platform": platform,
    "plannedTime": plannedTime,
    "estimatedTime": estimatedTime,
  };
}