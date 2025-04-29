import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'types/coordinate.dart';
import 'types/journey.dart';
import 'types/journey_point.dart';
import 'types/journey_position.dart';
import 'types/line.dart';
import 'types/line_path.dart';
import 'types/service_journey.dart';
import 'types/stop_area.dart';
import 'types/trip.dart';
import 'types/trip_legs.dart';

class InternetHandler {
  static const tokenURL = "https://ext-api.vasttrafik.se/token";
  static const baseURL = "https://ext-api.vasttrafik.se/pr/v4";

  static var token = ' ';

  static Future<String> fetchToken() async {
    final url = Uri.parse(tokenURL);
    const clientId = "kAE0WC5agVNGZ5Kh80jGZbie0QUa";
    const clientSecret = "GM8E0GJy1gKULbO6W6KHDMNAFxYa";
    final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));
    var response = await http.post(
      url,
      headers: {
        "Authorization": 'Basic $basicAuth',
        "Content-Type": 'application/x-www-form-urlencoded',
      },
      body: { 'grant_type': 'client_credentials' }
    );

    if (response.statusCode == 200) {
      debugPrint(jsonDecode(response.body)['access_token']);
      return jsonDecode(response.body)['access_token'];
    } else {
      debugPrint(response.body);
      throw Exception("Unable to fetch access token (${response.statusCode}: ${response.reasonPhrase})");
    }
  }

  static Future<List<StopArea>> fetchStopAreas(String search) async {
    if (search.isEmpty) {
      return [];
    }

    debugPrint("FETCHING STOP AREAS");

    final url = Uri.parse("$baseURL/locations/by-text?q=$search&limit=30&types=stoparea");
    var response = await http.get(url, headers: { "Authorization": 'Bearer $token', "Content-Type": 'application/json' });

    if (response.statusCode == 200) {
      debugPrint(response.body);
      List<dynamic> jsonList = jsonDecode(response.body)["results"];
      return jsonList.map((json) => StopArea.fromJson(json)).toList();
    } else {
      throw Exception("Unable to fetch stop areas (${response.statusCode}: ${response.reasonPhrase})");
    }
  }

  static Future<List<Journey>> fetchJourneys(List<StopArea> fromStops, List<StopArea> toStops) async {
    for (StopArea from in fromStops) {
      if (toStops.any((to) => to.gid == from.gid)) {
        throw Exception("Origin and destination stops cannot be the same");
      }
    }

    List<Journey> journeys = [];

    for (StopArea from in fromStops) {
      for (StopArea to in toStops) {
        Uri url = Uri.parse("$baseURL/journeys?originGid=${from.gid}&destinationGid=${to.gid}");
        var response = await http.get(url, headers: { "Authorization": 'Bearer $token', "Content-Type": 'application/json' });

        debugPrint("FETCHING JOURNEYS FROM ${from.name} TO ${to.name}, status code: ${response.statusCode}");
        debugPrint(url.toString());

        if (response.statusCode == 200) {
          debugPrint(response.body);
          
          var responseJson = jsonDecode(response.body);
          for (var journey in responseJson["results"]) {
            if (!journey.containsKey("tripLegs") || journey["tripLegs"] == null || journey["tripLegs"].length == 0) {
              continue;
            }

            String? reconstructionReference = journey["reconstructionReference"];
            String? detailsReference = journey["detailsReference"];

            List<Trip> trips = [];
            for (var tripJson in journey["tripLegs"]) {
              ServiceJourney serviceJourney = ServiceJourney.fromJson(tripJson["serviceJourney"]);
              JourneyPoint origin = JourneyPoint.fromJson(tripJson["origin"]);
              JourneyPoint destination = JourneyPoint.fromJson(tripJson["destination"]);
              TripLegs tripLegs = TripLegs(origin, destination);
              bool isCancelled = tripJson["isCancelled"];
              bool isPartCancelled = tripJson["isPartCancelled"];

              trips.add(Trip(serviceJourney, tripLegs, isCancelled, isPartCancelled));
            }

            journeys.add(Journey(trips, reconstructionReference, detailsReference));
          }
        } else {
          throw Exception("Unable to fetch journeys (${response.statusCode}: ${response.reasonPhrase})");
        }
      }
    }

    return journeys..sort((a, b) => a.trips.last.tripLegs.destination.estimatedTime.compareTo(b.trips.last.tripLegs.destination.estimatedTime));
  }

  static Future<Journey> fetchJourneyDetails(Journey journey) async {
    if (journey.detailsReference == null) {
      throw Exception("No details reference found");
    }
    
    Uri url = Uri.parse("$baseURL/journeys/${journey.detailsReference}/details?includes=triplegcoordinates");
    var response = await http.get(url, headers: { "Authorization": 'Bearer $token', "Content-Type": 'application/json' });

    if (response.statusCode == 200) {
      debugPrint("FETCHING JOURNEY DETAILS");
      debugPrint(url.toString());
      debugPrint(response.body);

      var responseJson = jsonDecode(response.body);
      var tripLegs = responseJson["tripLegs"];
      
      List<Trip> trips = [];
      for (var tripLeg in tripLegs) {
        var calls = tripLeg["callsOnTripLeg"];

        ServiceJourney serviceJourney = ServiceJourney.fromJson(tripLeg["serviceJourney"] ?? tripLeg["serviceJourneys"][0]);
        JourneyPoint origin = JourneyPoint.fromJson(calls[0]);
        JourneyPoint destination = JourneyPoint.fromJson(calls[calls.length - 1]);
        List<JourneyPoint> stops = [];
        for (int i = 1; i < calls.length - 1; i++) {
          stops.add(JourneyPoint.fromJson(calls[i]));
        }
        TripLegs tripLegs = TripLegs(origin, destination, stops);
        bool isCancelled = tripLeg["isCancelled"];
        bool isPartCancelled = tripLeg["isPartCancelled"];
        
        trips.add(Trip(serviceJourney, tripLegs, isCancelled, isPartCancelled));
      }

      return Journey(trips, journey.reconstructionReference, journey.detailsReference);
    } else {
      throw Exception("Unable to fetch journey details (${response.statusCode}: ${response.reasonPhrase})");
    }
  }

  static Future<List<LinePath>> fetchJourneyLinePath(Journey journey) async {
    if (journey.detailsReference == null) {
      throw Exception("No details reference found");
    }

    String detailsReferencePadded = journey.detailsReference!.padRight((journey.detailsReference!.length + 3) ~/ 4 * 4, '=');
    String decodedDetailsReference = utf8.decode(base64Url.decode(detailsReferencePadded));
    Map<String, dynamic> detailsReferenceJson = jsonDecode(decodedDetailsReference);
    if (detailsReferenceJson.containsKey("T")) {
      for (int i = 0; i < detailsReferenceJson["T"].length; i++) {
        detailsReferenceJson["T"][i].remove("O");
        detailsReferenceJson["T"][i].remove("D");
      }
    }
    detailsReferenceJson.remove("C");
    String newDetailsReference = base64Url.encode(utf8.encode(jsonEncode(detailsReferenceJson)));

    Uri url = Uri.parse("$baseURL/journeys/$newDetailsReference/details?includes=triplegcoordinates");
    var response = await http.get(url, headers: { "Authorization": 'Bearer $token', "Content-Type": 'application/json' });

    if (response.statusCode == 200) {
      debugPrint("FETCHING JOURNEY LINE PATH");
      debugPrint(url.toString());
      debugPrint(response.body);

      var responseJson = jsonDecode(response.body);
      var tripLegs = responseJson["tripLegs"];

      List<LinePath> linePaths = [];
      for (var tripLeg in tripLegs) {
        Line line = Line.fromJson(tripLeg["serviceJourneys"][0]["line"]);
        List<StopArea> stops = (tripLeg["callsOnTripLeg"] as List).map((call) => StopArea.fromJson(call["stopPoint"]["stopArea"])).toList();
        List<Coordinate> path = (tripLeg["tripLegCoordinates"] as List).map((coord) => Coordinate(coord["latitude"], coord["longitude"])).toList();
        linePaths.add(LinePath(line, stops, path));
      }

      debugPrint(linePaths.toString());

      return linePaths;
    } else {
      throw Exception("Unable to fetch journey line path (${response.statusCode}: ${response.reasonPhrase})");
    }
  }

  static Future<List<JourneyPosition>> fetchJourneyPosition(Journey journey) async {
    if (journey.detailsReference == null) {
      throw Exception("No details reference found");
    }

    Coordinate vgrLowerLeft = Coordinate(57.03, 10.98);
    Coordinate vgrUpperRight = Coordinate(59.28, 14.94);

    Uri url = Uri.parse("$baseURL/positions?lowerLeftLat=${vgrLowerLeft.latitude}&lowerLeftLong=${vgrLowerLeft.longitude}&upperRightLat=${vgrUpperRight.latitude}&upperRightLong=${vgrUpperRight.longitude}&detailsReferences=${journey.detailsReference}");
    var response = await http.get(url, headers: { "Authorization": 'Bearer $token', "Content-Type": 'application/json' });

    debugPrint("FETCHING JOURNEY POSITION");
    debugPrint(url.toString());

    if (response.statusCode == 200) {
      var responseJson = jsonDecode(response.body);

      debugPrint(response.body);
      if (responseJson.isNotEmpty) {
        List<JourneyPosition> journeyPositions = [];
        for (var journeyPos in responseJson) {
          Line line = Line.fromJson(journeyPos["line"]);
          Coordinate coord = Coordinate(journeyPos["latitude"], journeyPos["longitude"]);
          journeyPositions.add(JourneyPosition(journeyPos["detailsReference"], line, coord));
        }

        return journeyPositions;
      }

      throw Exception("No positions found");
    } else {
      throw Exception("Unable to fetch journey position (${response.statusCode}: ${response.reasonPhrase})");
    }
  }
}