import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/model.dart';
import '../models/types/journey.dart';
import '../models/types/journey_position.dart';
import '../models/types/recent_trip.dart';
import '../models/types/stop_area.dart';
import '../views/trip_display_strategy.dart';
import '../views/recent_trips_display_strategy.dart';
import '../views/stop_search_result_display_strategy.dart';
import '../views/journey_search_result_display_strategy.dart';
import '../views/journey_details_page.dart';
import '../controllers/location_controller.dart';
import '../utils/utils.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  Model model = Model();
  LocationController locationController = LocationController();

  int currentPageIndex = 0;
  SearchSelection currentSelection = SearchSelection.none;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();
  final ValueNotifier<List<StopArea>> _fromStopsNotifier = ValueNotifier([]);
  final ValueNotifier<List<StopArea>> _toStopsNotifier = ValueNotifier([]);
  late Position currentPos;
  List<RecentTrip> recentTrips = [];
  List<StopArea> stopsSearchResult = [];
  List<Journey> journeysSearchResult = [];
  late TripDisplayStrategy currentDisplayStrategy;

  Widget _buildTextField(String labelText, TextEditingController controller, FocusNode focusNode, List<StopArea> selectedStops, Function(StopArea stop) onDelete) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(labelText, style: Theme.of(context).textTheme.labelSmall),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <InputChip>[
                    ...(selectedStops.map((stop) =>
                      InputChip(
                        label: Text(stop.name.split(", ")[0], style: const TextStyle(fontSize: 12.0)),
                        onDeleted: onDelete(stop),
                        visualDensity: VisualDensity.compact,
                      )
                    ))
                  ]
                ),
              ),
            ]
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              border: const OutlineInputBorder(),
              hintText: selectedStops.isEmpty ? "Search for a stop" : "Search for another stop",
              suffixIcon: IconButton(onPressed: () => controller.clear(), icon: const Icon(Icons.clear)),
            ),
          )
        ]
      )
    );
  }

  void setTripDisplay() {
    if (_fromStopsNotifier.value.isNotEmpty && _toStopsNotifier.value.isNotEmpty && currentSelection == SearchSelection.none) {
      setState(() {
        _fromFocus.unfocus();
        _toFocus.unfocus();
      });

      void onClick(Journey journey) {
        final currentContext = context;
        model.getJourneyDetails(journey).then((journeyDetails) {
          model.getJourneyLinePath(journey).then((paths) {
            if (currentContext.mounted) {
              Future<List<JourneyPosition>> getJourneyPositions(Journey journey) async {
                return await model.getJourneyPosition(journey);
              }
              Navigator.push(currentContext, MaterialPageRoute(builder: (context) => JourneyDetailsPage(journey: journeyDetails, linePaths: paths, onPositionUpdate: getJourneyPositions, locationController: locationController)));
            }
          });
        });
      }
      setState(() => currentDisplayStrategy = JourneySearchResultDisplayStrategy(journeysSearchResult, onClick));
    } else {
      switch (currentSelection) {
        case SearchSelection.from:
          void onClick(StopArea stop) => setState(() {
            _fromStopsNotifier.value = [..._fromStopsNotifier.value, stop];
            _fromController.clear();
            _fromFocus.unfocus();
            _toStopsNotifier.value.isEmpty ? _toFocus.requestFocus() : null;
            locationController.stopListening();
          });
          setState(() => currentDisplayStrategy = StopSearchResultDisplayStrategy(stopsSearchResult, onClick, locationController));
        case SearchSelection.to:
          void onClick(StopArea stop) => setState(() {
            _toStopsNotifier.value = [..._toStopsNotifier.value, stop];
            _toController.clear();
            _toFocus.unfocus();
            _fromStopsNotifier.value.isEmpty ? _fromFocus.requestFocus() : null;
            locationController.stopListening();
          });
          setState(() => currentDisplayStrategy = StopSearchResultDisplayStrategy(stopsSearchResult, onClick, locationController));        
        default:
          void onClick(RecentTrip recentTrip) => setState(() {
            _fromStopsNotifier.value = [...recentTrip.origins];
            _toStopsNotifier.value = [...recentTrip.destinations];
          });
          void onFavoriteToggle(RecentTrip recentTrip) {
            model.toggleRecentTripFavorite(recentTrip);
            setState(() {
              for (var trip in recentTrips) {
                trip == recentTrip ? trip.isFavorite = !trip.isFavorite : null;
              }
            });
          }
          setState(() => currentDisplayStrategy = RecentTripsDisplayStrategy(recentTrips, onClick, onFavoriteToggle));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    model.getRecentTrips().then((trips) => setState(() => recentTrips = trips));

    void onLocationChanged() => setState(() => currentPos = locationController.currentPos);
    locationController.setOnLocationUpdate(onLocationChanged);

    _fromFocus.addListener(() => setState(() => currentSelection = _fromFocus.hasFocus ? SearchSelection.from : SearchSelection.none));
    _toFocus.addListener(() => setState(() => currentSelection = _toFocus.hasFocus ? SearchSelection.to : SearchSelection.none));

    void onStopSearch(String search) => model.searchStops(search).then((stops) => setState(() => stopsSearchResult = stops));
    Timer? debounce;
    void onSearchChanged(String query) {
      if (debounce?.isActive ?? false) debounce!.cancel();
      debounce = Timer(const Duration(milliseconds: 250), () {
      onStopSearch(query);
      });
    }

    _fromController.addListener(() => onSearchChanged(_fromController.text));
    _toController.addListener(() => onSearchChanged(_toController.text));

    Future<void> fetchJourneyData() async {
      return await model.searchJourneys(_fromStopsNotifier.value, _toStopsNotifier.value);
      // setState(() => journeysSearchResult = journeys);
    }
    _fromStopsNotifier.addListener(() {
      if (_fromStopsNotifier.value.isNotEmpty && _toStopsNotifier.value.isNotEmpty) {
        fetchJourneyData().then();
        setState(() => model.saveRecentTrip(_fromStopsNotifier.value, _toStopsNotifier.value));
      }
    });
    _toStopsNotifier.addListener(() {
      if (_fromStopsNotifier.value.isNotEmpty && _toStopsNotifier.value.isNotEmpty) {
        fetchJourneyData();
        setState(() => model.saveRecentTrip(_fromStopsNotifier.value, _toStopsNotifier.value));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _fromController.dispose();
    _toController.dispose();
    _fromStopsNotifier.dispose();
    _toStopsNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("CALLING BUILD");
    setTripDisplay();

    void onDeleteFromStop(StopArea stop) => () => setState(() {
      _fromStopsNotifier.value = _fromStopsNotifier.value.where((s) => s != stop).toList();
      if (_fromStopsNotifier.value.isEmpty) { _fromFocus.requestFocus(); }
    });
    void onDeleteToStop(StopArea stop) => () => setState(() {
      _toStopsNotifier.value = _toStopsNotifier.value.where((s) => s != stop).toList();
      if (_toStopsNotifier.value.isEmpty) { _toFocus.requestFocus(); }
    });
    void swapStops() {
      setState(() {
        final temp = _fromStopsNotifier.value;
        _fromStopsNotifier.value = _toStopsNotifier.value;
        _toStopsNotifier.value = temp;

        if (_toStopsNotifier.value.isEmpty && _fromStopsNotifier.value.isNotEmpty) {
          _toFocus.requestFocus();
        } else if (_fromStopsNotifier.value.isEmpty && _toStopsNotifier.value.isNotEmpty) {
          _fromFocus.requestFocus();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("Search trip"),
      ),
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildTextField("From: ", _fromController, _fromFocus, _fromStopsNotifier.value, onDeleteFromStop)),
                IconButton(
                  onPressed: () {  },
                  icon: Icon(Icons.filter_alt, size: 32.0, color: Theme.of(context).colorScheme.primary),
                ),
              ]
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildTextField("To: ", _toController, _toFocus, _toStopsNotifier.value, onDeleteToStop)),
                IconButton(
                  onPressed: () => swapStops(),
                  icon: Icon(Icons.swap_vert, size: 32.0, color: Theme.of(context).colorScheme.primary),
                ),
              ]
            ),
            Expanded(child: currentDisplayStrategy.buildWidget(context),
            )
          ]
        )
      ),

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
            } else {
              currentPageIndex = index;
            }
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.trip_origin, color: Theme.of(context).colorScheme.onPrimaryContainer),
            icon: Icon(Icons.trip_origin_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            label: 'Trips',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.departure_board, color: Theme.of(context).colorScheme.onPrimaryContainer),
            icon: Icon(Icons.departure_board_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            label: 'Departures',
          ),
        ],
      ),
    );
  }
}