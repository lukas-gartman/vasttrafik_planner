import 'package:flutter/material.dart';

enum TextSelection { from, to, none }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Västtrafik Planner 2.0',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const TripsPage(),
    );
  }
}

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  int currentPageIndex = 0;
  TextSelection currentSelection = TextSelection.none;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  static final List<Trip> _trips = [
    Trip(Stop("Brunnsparken"), Stop("Chalmers"), true),
    Trip(Stop("Centralstationen"), Stop("Lindholmen"), true),
    Trip(Stop("Järntorget"), Stop("Sahlgrenska"), false),
    Trip(Stop("Korsvägen"), Stop("Liseberg")),
    Trip(Stop("Nordstan"), Stop("Hjalmar Brantingsplatsen")),
    Trip(Stop("Gamlestaden"), Stop("Redbergsplatsen")),
    Trip(Stop("Wieselgrensplatsen"), Stop("Kortedala")),
    Trip(Stop("Frölunda Torg"), Stop("Marklandsgatan")),
    Trip(Stop("Hisingen"), Stop("Backaplan")),
    Trip(Stop("Angered"), Stop("Hammarkullen")),
    Trip(Stop("Mölndal"), Stop("Krokslätt")),
    Trip(Stop("Linnéplatsen"), Stop("Botaniska Trädgården")),
    Trip(Stop("Svingeln"), Stop("Olskroken")),
    Trip(Stop("Redbergsplatsen"), Stop("Östra Sjukhuset")),
    Trip(Stop("Kungsportsplatsen"), Stop("Valand")),
    Trip(Stop("Domkyrkan"), Stop("Järntorget")),
    Trip(Stop("Vasaplatsen"), Stop("Chalmers")),
    Trip(Stop("Sahlgrenska"), Stop("Linnéplatsen")),
    Trip(Stop("Liseberg"), Stop("Korsvägen")),
    Trip(Stop("Hjalmar Brantingsplatsen"), Stop("Nordstan")),
    Trip(Stop("Lindholmen"), Stop("Centralstationen")),
    Trip(Stop("Chalmers"), Stop("Brunnsparken")),
    Trip(Stop("Marklandsgatan"), Stop("Frölunda Torg")),
    Trip(Stop("Backaplan"), Stop("Hisingen")),
  ];

  static final List<Stop> _stops = [
    Stop("Brunnsparken"), Stop("Chalmers"), Stop("Centralstationen"), Stop("Lindholmen"),
    Stop("Järntorget"), Stop("Sahlgrenska"), Stop("Korsvägen"), Stop("Liseberg"),
    Stop("Nordstan"), Stop("Hjalmar Brantingsplatsen"), Stop("Gamlestaden"), Stop("Redbergsplatsen"),
    Stop("Wieselgrensplatsen"), Stop("Kortedala"), Stop("Frölunda Torg"), Stop("Marklandsgatan"),
    Stop("Hisingen"), Stop("Backaplan"), Stop("Angered"), Stop("Hammarkullen"),
    Stop("Mölndal"), Stop("Krokslätt"), Stop("Linnéplatsen"), Stop("Botaniska Trädgården"),
    Stop("Svingeln"), Stop("Olskroken"), Stop("Östra Sjukhuset"), Stop("Kungsportsplatsen"),
    Stop("Valand"), Stop("Domkyrkan"), Stop("Vasaplatsen")
  ];

  TripDisplayStrategy currentDisplayStrategy = RecentTripsDisplayStrategy(_trips);

  Widget _buildTextField(String labelText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  List<Stop> searchStops(String search) => _stops.where((stop) => stop.name.toLowerCase().contains(search.toLowerCase())).toList();

  void setTripDisplay() {
    switch (currentSelection) {
      case TextSelection.from:
        if (_fromController.text.isNotEmpty) {
          setState(() => currentDisplayStrategy = StopSearchResultDisplayStrategy(searchStops(_fromController.text)));
        }
      case TextSelection.to:
        if (_toController.text.isNotEmpty) {
          setState(() => currentDisplayStrategy = StopSearchResultDisplayStrategy(searchStops(_toController.text)));
        }
      default:
        setState(() => currentDisplayStrategy = RecentTripsDisplayStrategy(_trips));
    }
  }

  @override
  void initState() {
    super.initState();

    _fromController.addListener(() => setState(() => currentSelection = (_fromController.text.isEmpty && _toController.text.isEmpty) ? TextSelection.none : TextSelection.from));
    _toController.addListener(() => setState(() => currentSelection = (_fromController.text.isEmpty && _toController.text.isEmpty) ? TextSelection.none : TextSelection.to));
  }

  @override
  void dispose() {
    super.dispose();
    _fromController.dispose();
    _toController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setTripDisplay();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Search trip"),
      ),
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _buildTextField("From: ", _fromController),
            _buildTextField("To: ", _toController),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: currentDisplayStrategy.buildWidget(context),
              ),
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
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.trip_origin),
            icon: Icon(Icons.trip_origin_outlined),
            label: 'Trips',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.departure_board),
            icon: Icon(Icons.departure_board_outlined),
            label: 'Departures',
          ),
        ],
      ),
    );
  }
}

abstract class TripDisplayStrategy<T> {
  final T data;
  TripDisplayStrategy(this.data);

  Widget buildWidget(BuildContext context);
}

class RecentTripsDisplayStrategy implements TripDisplayStrategy<List<Trip>> {
  @override
  final List<Trip> data;
  RecentTripsDisplayStrategy(this.data);

  @override
  Widget buildWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        Text("Favourites", style: Theme.of(context).textTheme.titleMedium),
        for (Trip trip in data.where((trip) => trip.isFavorite))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(children: <Widget>[Text(trip.from.name), const Text(" -> "), Text(trip.to.name)]),
          ),
        Text("Recent searches", style: Theme.of(context).textTheme.titleMedium),
        for (Trip trip in data.where((trip) => !trip.isFavorite))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(children: <Widget>[Text(trip.from.name), const Text(" -> "), Text(trip.to.name)]),
          )
      ],
    );
  }
}

class StopSearchResultDisplayStrategy implements TripDisplayStrategy<List<Stop>> {
  @override
  final List<Stop> data;
  StopSearchResultDisplayStrategy(this.data);

  @override
  Widget buildWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (Stop stop in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(children: <Widget>[Text(stop.name)]),
          ),
      ],
    );
  }
}

class LineSearchResultDisplayStrategy implements TripDisplayStrategy<List<Line>> {
  @override
  final List<Line> data;
  LineSearchResultDisplayStrategy(this.data);

  @override
  Widget buildWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (Line line in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(children: <Widget>[Text(line.id), Text("From: ${line.from.name}"), Text("To: ${line.to.name}")]),
          ),
      ],
    );
  }
}

class Stop {
  final String name;

  Stop(this.name);
}

class Trip {
  final Stop from;
  final Stop to;
  final bool isFavorite;

  Trip(this.from, this.to, [this.isFavorite = false]);
}

class Line {
  final String id;
  final String type;
  final Stop from;
  final Stop to;

  Line(this.id, this.type, this.from, this.to);
}