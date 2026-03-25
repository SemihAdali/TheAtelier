import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../screens/trip_detail_screen.dart';
import '../services/weather_service.dart';

class TravelPlannerScreen extends StatefulWidget {
  const TravelPlannerScreen({super.key});

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  List<Trip> _trips = [];
  
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _trips = StorageService.instance.getTrips();
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _trips = StorageService.instance.getTrips();
    });
  }

  String _getDestinationImage(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('paris')) return 'https://images.unsplash.com/photo-1502602898657-3e917d47aa3e?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('milan') || d.contains('italy')) return 'https://images.unsplash.com/photo-1522083111817-e837ea8bea90?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('london')) return 'https://images.unsplash.com/photo-1513635269975-59693e24fb79?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('york')) return 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('tokyo')) return 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('munich') || d.contains('münchen')) return 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('berlin')) return 'https://images.unsplash.com/photo-1560969184-10fe8719e047?q=80&w=2070&auto=format&fit=crop';
    if (d.contains('rome') || d.contains('rom')) return 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=2070&auto=format&fit=crop';
    
    final cityTerm = desc.split(',')[0].trim();
    return 'https://loremflickr.com/800/600/${Uri.encodeComponent(cityTerm)},landmark,city';
  }

  Future<void> _createNewTrip() async {
    final titleController = TextEditingController();
    CityLocation? selectedCity;
    DateTimeRange? selectedDates;
    String? selectedPurpose = 'Vacation';
    final List<String> purposes = ['Vacation', 'Business', 'City Trip', 'Concert', 'Event', 'Skiing'];
    bool isLoadingWeather = false;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            title: const Text('Create New Trip'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Trip Name (e.g. Milan Fashion Week)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPurpose,
                    decoration: const InputDecoration(labelText: 'Purpose'),
                    items: purposes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setStateBuilder(() => selectedPurpose = v),
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<CityLocation>(
                    displayStringForOption: (option) => option.displayName,
                    optionsBuilder: (textEditingValue) async {
                      if (textEditingValue.text.isEmpty) return const Iterable<CityLocation>.empty();
                      return await _locationService.searchCities(textEditingValue.text);
                    },
                    onSelected: (selection) => setStateBuilder(() => selectedCity = selection),
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Destination (Type to search)'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setStateBuilder(() => selectedDates = picked);
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(selectedDates == null
                        ? 'Select Dates'
                        : '${selectedDates!.start.toLocal().toString().split(' ')[0]} to ${selectedDates!.end.toLocal().toString().split(' ')[0]}'),
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingWeather) const CircularProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: (selectedCity == null || selectedDates == null || isLoadingWeather)
                    ? null
                    : () async {
                        setStateBuilder(() => isLoadingWeather = true);
                        
                        final weather = await _weatherService.fetchWeatherForTrip(
                          selectedCity!.latitude,
                          selectedCity!.longitude,
                          selectedDates!.start,
                          selectedDates!.end,
                        );

                        if(!context.mounted) return;
                        setStateBuilder(() => isLoadingWeather = false);
                        Navigator.pop(ctx, true);

                        _finalizeTripCreation(
                          titleController.text,
                          selectedCity!,
                          selectedDates!,
                          selectedPurpose ?? 'Vacation',
                          weather,
                        );
                      },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _finalizeTripCreation(
    String customTitle,
    CityLocation city,
    DateTimeRange dates,
    String purpose,
    WeatherForecast? weather,
  ) async {
    final title = customTitle.isNotEmpty ? customTitle : '${city.displayName.split(',')[0]} $purpose';
    final imageUrl = _getDestinationImage(city.displayName);

    final newTrip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      destination: city.displayName,
      startDate: dates.start,
      endDate: dates.end,
      weatherTemp: weather?.temperature ?? 'Unknown',
      weatherDescription: weather?.description ?? 'N/A',
      purpose: purpose,
      latitude: city.latitude,
      longitude: city.longitude,
      imageUrl: imageUrl,
    );

    await StorageService.instance.addTrip(newTrip);
    setState(() {
      _trips.insert(0, newTrip);
    });
  }

  Future<void> _deleteTrip(Trip trip) async {
    setState(() {
      _trips.removeWhere((t) => t.id == trip.id);
    });
    await StorageService.instance.deleteTrip(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        _buildSliverHeader(theme, cs),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCreateTripButton(cs, theme),
                const SizedBox(height: 32),
                if (_trips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No journeys planned yet.\nTap below to start curating your next experience.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  ..._trips.map((trip) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildTripCard(trip, cs, theme),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader(ThemeData theme, ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CURATION JOURNEY',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                color: cs.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Travel Planner',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTripButton(ColorScheme cs, ThemeData theme) {
    return Container(
      width: 200,
      child: FilledButton.icon(
        onPressed: _createNewTrip,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Create New Trip'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5D634F), // Derived from screenshot
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip, ColorScheme cs, ThemeData theme) {
    final startStr = trip.startDate.toLocal().toString().split(' ')[0];
    final endStr = trip.endDate.toLocal().toString().split(' ')[0];

    return Dismissible(
      key: Key(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTrip(trip),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
          );
          _refreshTrips(); // Refresh to catch any packing list changes
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(trip.imageUrl ?? _getDestinationImage(trip.destination)),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      trip.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${trip.destination} • $startStr to $endStr',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildWeatherStat(null, '${trip.weatherTemp}', trip.weatherDescription ?? ''),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData? icon, String value, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(width: 8),
        Text(
          description.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }


}
