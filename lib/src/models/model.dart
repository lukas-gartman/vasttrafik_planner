import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:geolocator/geolocator.dart';

import 'internet_handler.dart';
import 'location_handler.dart';
import 'types/coordinate.dart';
import 'types/journey.dart';
import 'types/journey_position.dart';
import 'types/line_path.dart';
import 'types/recent_trip.dart';
import 'types/stop_area.dart';

class Model {
  var _prevStopSearch = '';
  var _token = ' ';
  
  get token => _token;

  Model() {
    _setup();
  }

  void _setup() async {
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    const prefsToken = "token";
    String? savedToken = sharedPrefs.getString(prefsToken);

    if (savedToken != null && !JwtDecoder.isExpired(savedToken)) {
      debugPrint("token saved: $savedToken");
      _token = savedToken;
      InternetHandler.token = _token;
    } else {
      var fetchedToken = await InternetHandler.fetchToken();

      debugPrint("token fetched: $fetchedToken");

      _token = fetchedToken;
      InternetHandler.token = _token;
      var success = await sharedPrefs.setString(prefsToken, token);
      if (success) {
        debugPrint("token saved");
      }
    }
  }

  Future<List<RecentTrip>> getRecentTrips() async {
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.remove("recentTrips");
    List<String> recentTrips = sharedPrefs.getStringList("recentTrips") ?? [];
    debugPrint("RECENT TRIPS LENGTH: ${recentTrips.length}");
    List<RecentTrip> recentTripsList = recentTrips.map((json) => RecentTrip.fromJson(jsonDecode(json))).toList();

    return recentTripsList..sort((a, b) => b.lastSearched.compareTo(a.lastSearched));
  }

  Future<void> _saveRecentTrips(List<RecentTrip> recentTripsList) async {
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    List<String> updatedRecentTrips = recentTripsList.map((trip) => jsonEncode(trip.toJson())).toList();
    await sharedPrefs.setStringList("recentTrips", updatedRecentTrips);
  }

  Future<void> saveRecentTrip(List<StopArea> origins, List<StopArea> destinations) async {
    List<RecentTrip> recentTripsList = await getRecentTrips();

    bool tripExists = false;
    for (var trip in recentTripsList) {
      tripExists = origins.every((o) => trip.origins.any((origin) => origin.gid == o.gid)) && destinations.every((d) => trip.destinations.any((destination) => destination.gid == d.gid));
      if (tripExists) {
        trip.lastSearched = DateTime.now();
        await _saveRecentTrips(recentTripsList);
        break;
      }
    }

    if (!tripExists) {
      recentTripsList.add(RecentTrip(origins, destinations));
    }

    await _saveRecentTrips(recentTripsList);
  }

  Future<void> toggleRecentTripFavorite(RecentTrip trip) async {
    List<RecentTrip> recentTripsList = await getRecentTrips();

    for (var savedTrip in recentTripsList) {
      bool tripExists = trip.origins.every((o) => savedTrip.origins.any((origin) => origin.gid == o.gid)) && trip.destinations.every((d) => savedTrip.destinations.any((destination) => destination.gid == d.gid));
      if (tripExists) {
        savedTrip.isFavorite = !savedTrip.isFavorite;
        await _saveRecentTrips(recentTripsList);
        break;
      }
    }
  }

  Future<List<StopArea>> searchStops(String search) async {
    Position currentPos = await LocationHandler.getCurrentPosition();
    Coordinate currentCoord = Coordinate(currentPos.latitude, currentPos.longitude);

    debugPrint("searching for $search");
    debugPrint("current pos: ${currentPos.latitude}, ${currentPos.longitude}");

    if (search != _prevStopSearch) {
      _prevStopSearch = search;
      List<StopArea> stopAreas = await InternetHandler.fetchStopAreas(search);
      stopAreas.sort((a,b) => Coordinate.calculateDistance(currentCoord, a.coord).compareTo(Coordinate.calculateDistance(currentCoord, b.coord)));
      return stopAreas;
    }
    return [];
  }

  Future<List<Journey>> searchJourneys(List<StopArea> fromStops, List<StopArea> toStops) async {
    debugPrint("SEARCHING FOR JOURNEYS");
    List<Journey> journeys = await InternetHandler.fetchJourneys(fromStops, toStops);
    return journeys;
  }

  Future<Journey> getJourneyDetails(Journey journey) async {
    return await InternetHandler.fetchJourneyDetails(journey);
  }

  Future<List<LinePath>> getJourneyLinePath(Journey journey) async {
    return await InternetHandler.fetchJourneyLinePath(journey);
  }

  Future<List<JourneyPosition>> getJourneyPosition(Journey journey) async {
    return await InternetHandler.fetchJourneyPosition(journey);
  }
}
