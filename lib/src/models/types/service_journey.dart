import 'line.dart';

class ServiceDirectionDetails {
  bool isFrontEntry;
  String direction;
  String? directionVia;
  String? replaces;

  ServiceDirectionDetails(this.isFrontEntry, this.direction, [this.directionVia, this.replaces]);
  ServiceDirectionDetails.fromJson(Map<String, dynamic> json):
    isFrontEntry = json["isFrontEntry"] ?? false,
    direction = json["shortDirection"],
    directionVia = json["via"],
    replaces = json["replaces"];

  Map<String, dynamic> toJson() => {
    "isFrontEntry": isFrontEntry,
    "shortDirection": direction,
    "via": directionVia,
    "replaces": replaces,
  };
}

class ServiceJourney {
  String gid;
  Line line;
  ServiceDirectionDetails directionDetails;

  ServiceJourney(this.gid, this.line, this.directionDetails);

  ServiceJourney.fromJson(Map<String, dynamic> json):
    gid = json["gid"],
    line = Line.fromJson(json["line"]),
    directionDetails = ServiceDirectionDetails.fromJson(json["directionDetails"]);

  Map<String, dynamic> toJson() => {
    "gid": gid,
    "line": line.toJson(),
    "directionDetails": directionDetails.toJson(),
  };
}