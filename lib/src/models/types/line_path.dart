import 'line.dart';
import 'stop_area.dart';
import 'coordinate.dart';

class LinePath {
  Line line;
  List<StopArea> stops;
  List<Coordinate> path;

  LinePath(this.line, this.stops, this.path);
}