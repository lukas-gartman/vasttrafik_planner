import 'coordinate.dart';

class StopArea {
  String gid;
  String name;
  Coordinate coord;

  StopArea(this.gid, this.name, this.coord);
  StopArea.fromJson(Map<String, dynamic> json) : gid = json["gid"], name = json["name"], coord = Coordinate.fromJson(json);
  Map<String, dynamic> toJson() => { "gid": gid, "name": name, "coord": coord.toJson() };
}