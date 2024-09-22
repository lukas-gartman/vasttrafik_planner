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
  final List<Stop> _fromStops = [];
  final List<Stop> _toStops = [];

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

  static final List<Line> _lines = [
    Line("1", "Bus", Stop("Brunnsparken"), Stop("Chalmers")),
    Line("2", "Tram", Stop("Centralstationen"), Stop("Lindholmen")),
    Line("3", "Bus", Stop("Järntorget"), Stop("Sahlgrenska")),
    Line("4", "Tram", Stop("Korsvägen"), Stop("Liseberg")),
    Line("5", "Bus", Stop("Nordstan"), Stop("Hjalmar Brantingsplatsen")),
  ];

  late TripDisplayStrategy currentDisplayStrategy;

  Widget _buildTextField(String labelText, TextEditingController controller, List<Stop> selectedStops) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(labelText, style: Theme.of(context).textTheme.labelSmall),
              ...selectedStops.map((stop) {
                return InputChip(
                  label: Text(stop.name),
                  onDeleted: () => setState(() => selectedStops.remove(stop)),
                );
              })
            ],
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Search for a stop',
              suffixIcon: IconButton(onPressed: () => controller.clear(), icon: const Icon(Icons.clear)),
            )
          )
        ]
      )
    );
  }

  void setTripDisplay() {
    List<Stop> searchStops(String search) => _stops.where((stop) => stop.name.toLowerCase().contains(search.toLowerCase())).toList();

    if (_fromStops.isNotEmpty && _toStops.isNotEmpty) {
      void onClick(Line line) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
      setState(() => currentDisplayStrategy = LineSearchResultDisplayStrategy(_lines, onClick));
    } else {
      switch (currentSelection) {
        case TextSelection.from:
          if (_fromController.text.isNotEmpty) {
            void onClick(Stop stop) => setState(() => setState(() => _fromStops.add(stop)));
            setState(() => currentDisplayStrategy = StopSearchResultDisplayStrategy(searchStops(_fromController.text), onClick));
          }
        case TextSelection.to:
          if (_toController.text.isNotEmpty) {
            void onClick(Stop stop) => setState(() => setState(() => _toStops.add(stop)));
            setState(() => currentDisplayStrategy = StopSearchResultDisplayStrategy(searchStops(_toController.text), onClick));
          }
        default:
          void onClick(Trip trip) => setState(() {
            _fromStops.add(trip.from);
            _toStops.add(trip.to);
          });
          setState(() => currentDisplayStrategy = RecentTripsDisplayStrategy(_trips, onClick));
      }
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
            _buildTextField("From: ", _fromController, _fromStops),
            _buildTextField("To: ", _toController, _toStops),
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
  final List<T> data;
  final Function(T) onClick;
  TripDisplayStrategy(this.data, this.onClick);

  Widget buildWidget(BuildContext context);
}

class RecentTripsDisplayStrategy implements TripDisplayStrategy<Trip> {
  @override
  final List<Trip> data;
  @override
  final Function(Trip) onClick;
  RecentTripsDisplayStrategy(this.data, this.onClick);

  @override
  Widget buildWidget(BuildContext context) {
    final List<Trip> favourites = data.where((trip) => trip.isFavorite).toList();
    final List<Trip> recentSearches = data.where((trip) => !trip.isFavorite).toList();
    Widget buildTripRow(Trip trip) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => onClick(trip),
            child: Text("${trip.from.name} -> ${trip.to.name}"),
          )
        )
      );
    }

    return ListView(
      children: <Widget>[
        Text("Favourites", style: Theme.of(context).textTheme.titleMedium),
        for (Trip trip in favourites)
          buildTripRow(trip),
        Text("Recent searches", style: Theme.of(context).textTheme.titleMedium),
        for (Trip trip in recentSearches)
          buildTripRow(trip),
      ],
    );
  }
}

class StopSearchResultDisplayStrategy implements TripDisplayStrategy<Stop> {
  @override
  final List<Stop> data;
  @override
  final Function(Stop) onClick;
  StopSearchResultDisplayStrategy(this.data, this.onClick);

  @override
  Widget buildWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (Stop stop in data)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onClick(stop),
                child: Text(stop.name),
              )
            )
          )
      ]
    );
  }
}

class LineSearchResultDisplayStrategy implements TripDisplayStrategy<Line> {
  @override
  final List<Line> data;
  @override
  final Function(Line) onClick;
  LineSearchResultDisplayStrategy(this.data, this.onClick);

  @override
  Widget buildWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (Line line in data)
          Padding(
            padding: const EdgeInsets.all(8.0),
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