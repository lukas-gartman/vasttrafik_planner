import 'package:flutter/material.dart';

import 'trip_display_strategy.dart';
import '../models/types/recent_trip.dart';

class RecentTripsDisplayStrategy extends TripDisplayStrategy<RecentTrip> {
  final Function(RecentTrip) onFavoriteToggle;
  RecentTripsDisplayStrategy(super.data, super.onClick, this.onFavoriteToggle);

  @override
  Widget buildWidget(BuildContext context) {
    final List<RecentTrip> favourites = data.where((trip) => trip.isFavorite).toList();
    final List<RecentTrip> recentSearches = data.where((trip) => !trip.isFavorite).toList();
    Widget buildTripRow(RecentTrip trip) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip.origins.map((stop) => stop.name.split(", ")[0]).join(", ")),
              Text(trip.destinations.map((stop) => stop.name.split(", ")[0]).join(", ")),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              trip.isFavorite ? Icons.star : Icons.star_border,
              color: trip.isFavorite ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            onPressed: () => onFavoriteToggle(trip),
          ),
          onTap: () => onClick(trip),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: <Widget>[
        if (data.isEmpty)
          const Text("No recent trips", style: TextStyle(fontSize: 16.0, color: Colors.grey), textAlign: TextAlign.center),
          
        if (favourites.isNotEmpty)
          Text("Favourites", style: Theme.of(context).textTheme.titleMedium),
        for (RecentTrip trip in favourites)
          buildTripRow(trip),
        
        if (recentSearches.isNotEmpty)
          Text("Recent searches", style: Theme.of(context).textTheme.titleMedium),
        for (RecentTrip trip in recentSearches)
          buildTripRow(trip),
      ],
    );
  }
}