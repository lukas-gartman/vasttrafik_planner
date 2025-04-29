import 'coordinate.dart';
import 'line.dart';

class JourneyPosition {
  String detailsReference;
  Line line;
  Coordinate coord;

  JourneyPosition(this.detailsReference, this.line, this.coord);
}