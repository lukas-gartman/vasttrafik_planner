import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import '../models/types/journey.dart';
import '../models/types/journey_position.dart';
import '../models/types/line_path.dart';
import '../models/types/journey_point.dart';
import '../models/types/line.dart';
import '../models/types/stop_area.dart';
import '../models/types/trip.dart';
import '../controllers/location_controller.dart';
import '../utils/utils.dart';

class JourneyDetailsPage extends StatefulWidget {
  final Journey journey;
  final List<LinePath> linePaths;
  final Function(Journey) onPositionUpdate;
  final LocationController locationController;
  const JourneyDetailsPage({super.key, required this.journey, required this.linePaths, required this.onPositionUpdate, required this.locationController});

  @override
  State<JourneyDetailsPage> createState() => _JourneyDetailsPage();
}

class _JourneyDetailsPage extends State<JourneyDetailsPage> with TickerProviderStateMixin {
  late final Journey journey;
  late final List<LinePath> linePaths;
  late final Function(Journey) onPositionUpdate;
  late final LocationController locationController;
  
  late final AnimatedMapController animatedMapController = AnimatedMapController(vsync: this);

  late final Timer journeyPositionTimer;
  bool followJourney = true;
  double currentZoom = 14.0;
  List<JourneyPosition> journeyPositions = [];

  @override
  void initState() {
    super.initState();
    journey = widget.journey;
    linePaths = widget.linePaths;
    onPositionUpdate = widget.onPositionUpdate;
    locationController = widget.locationController;

    locationController.startListening();

    updateLocations();
    journeyPositionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (journeyPositionTimer.isActive) {
        updateLocations();
      }
    });
  }

  @override
  void dispose() {
    journeyPositionTimer.cancel();
    animatedMapController.dispose();
    locationController.stopListening();
    super.dispose();
  }

  void moveCameraToJourneys() {
    if (journeyPositions.isNotEmpty) {
      animatedMapController.animatedFitCamera(
        duration: const Duration(seconds: 2),
        cameraFit: CameraFit.coordinates(
          coordinates: journeyPositions.map((pos) => locationController.toLatLng(pos.coord)).toList(),
          padding: const EdgeInsets.only(top: 128.0, bottom: 384.0, left: 64.0, right: 64.0),
          maxZoom: currentZoom
        ),
      );
    }
  }

  void updateLocations() {
    onPositionUpdate(journey).then((positions) {
      setState(() => journeyPositions = positions);
      if (followJourney) {
        moveCameraToJourneys();
      }
    }).catchError((error) {
      journeyPositionTimer.cancel();
    });
  }

  Column createStopDetailsColumn(JourneyPoint point, [bool isOriginOrDestination = false]) {
    return Column(
      children: [
        isOnTime(point)
          ? Row(children: [Text("${formatTime(point.plannedTime)} ")])
          : Row(children: [
                Text("${formatTime(point.estimatedTime)} "),
                Text("${formatTime(point.plannedTime)} ", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
            ]),
        
        isOriginOrDestination
          ? Row(children: [
              Text(point.stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(" (Platform ${point.platform})"),
            ])
          : Row(children: [Text(point.stop.name)]),
        
        const Divider(color: Colors.grey, thickness: 0.25),
      ],
    );
  }

  Column createTripColumn(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            createLineBadge(trip.serviceJourney.line),
            Text(" ${trip.serviceJourney.directionDetails.direction}"),
            if (trip.serviceJourney.directionDetails.directionVia != null)
              Text(" via ${trip.serviceJourney.directionDetails.directionVia}"),
          ],
        ),
        createStopDetailsColumn(trip.tripLegs.origin, true),
        if (trip.tripLegs.stops.length > 3)
          ExpansionTile(
            shape: const RoundedRectangleBorder(),
            dense: true,
            visualDensity: const VisualDensity(vertical: -4.0),
            title: Text("${trip.tripLegs.stops.length + 1} stops"),
            children: [
              for (JourneyPoint point in trip.tripLegs.stops) ...[
                createStopDetailsColumn(point)
              ],
            ],
          )
        else
          for (JourneyPoint point in trip.tripLegs.stops) ...[
            createStopDetailsColumn(point)
          ],
        createStopDetailsColumn(trip.tripLegs.destination, true),
      ],
    );
  }

  Container createTripContainer(Trip trip) {
    Line line = trip.serviceJourney.line;

    return Container(
      margin: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 12.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: hexToColor(line.borderColor == "#ffffff" ? line.backgroundColor : line.borderColor),
            width: 5.0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: createTripColumn(trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Journey Details"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: animatedMapController.mapController,
            options: MapOptions(
              initialCenter: locationController.toLatLng(journey.trips[0].tripLegs.origin.stop.coord),
              minZoom: 11.5,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onMapEvent: (event) {
                if (event is MapEventMove && event.source != MapEventSource.mapController && followJourney) {
                  setState(() {
                    followJourney = false;
                    currentZoom = event.camera.zoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                // urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                urlTemplate: "https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}@2x.png?key=TVqEExU4QT7IV8aBVu1w",
              ),
              PolylineLayer(
                polylines: [
                  for (LinePath linePath in linePaths) ...[
                    Polyline(
                      points: linePath.path.map((coord) => locationController.toLatLng(coord)).toList(),
                      strokeWidth: 5.0,
                      color: hexToColor(linePath.line.backgroundColor),
                      borderColor: hexToColor(linePath.line.borderColor),
                    ),
                  ]
                ],
              ),
              MarkerLayer(
                markers: [
                  for (LinePath linePath in linePaths) ...[
                    for (StopArea stop in linePath.stops) ...[
                      Marker(
                        width: 4.0 * (currentZoom / 18.0),
                        height: 4.0 * (currentZoom / 18.0),
                        point: locationController.toLatLng(stop.coord),
                        child: Container(decoration: BoxDecoration(color: hexToColor(linePath.line.foregroundColor), shape: BoxShape.circle)),
                      ),
                    ],
                  ],
                  for (JourneyPosition jPos in journeyPositions) ...[
                    Marker(
                      width: 35.0 * (currentZoom / 16.0),
                      height: 25.0 * (currentZoom / 16.0),
                      point: locationController.toLatLng(jPos.coord),
                      child: createLineBadge(jPos.line),
                    ),
                  ],
                  Marker(
                    width: 35.0 * (currentZoom / 16.0),
                    height: 35.0 * (currentZoom / 16.0),
                    point: locationController.currentLatLng,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), shape: BoxShape.circle),
                      child: Center(child: Icon(Icons.circle, color: Colors.lightBlue.shade300, size: 20.0 * (currentZoom / 16.0))),
                    ),
                  ),
                  Marker(
                    width: 100.0 * (currentZoom / 16.0),
                    height: 100.0 * (currentZoom / 16.0),
                    point: locationController.currentLatLng,
                    child: Transform.rotate(
                      angle: locationController.currentPos.heading * (3.141592653589793 / 180.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [Colors.blue.withOpacity(0.1), Colors.transparent], stops: const [0.5, 1.0]),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      onPressed: () {
                        setState(() {
                          followJourney = false;
                          currentZoom = 15.0;
                          animatedMapController.animateTo(dest: locationController.currentLatLng, zoom: currentZoom);
                        });
                      },
                      heroTag: "location",
                      child: const Icon(Icons.location_searching),
                    ),
                    const SizedBox(height: 8.0),
                    FloatingActionButton.small(
                      onPressed: () => setState(() {
                        currentZoom = currentZoom != 14.0 ? 14.0 : 15.0;
                        followJourney = true;
                        moveCameraToJourneys();
                      }),
                      heroTag: "follow",
                      child: const Icon(Icons.directions_transit),
                    ),
                  ],
                )
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 32.0,
                      height: 5.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4.0))
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: journey.trips.length,
                        itemBuilder: (BuildContext context, int index) {
                          return createTripContainer(journey.trips[index]);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      )
    );
  }
}