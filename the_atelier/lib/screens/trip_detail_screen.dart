import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/wardrobe_item.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;
  final AIService _aiService = AIService();
  bool _isGeneratingPackingList = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

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

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this journey? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await StorageService.instance.deleteTrip(_trip.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editTrip() async {
    final titleController = TextEditingController(text: _trip.title);
    CityLocation? selectedCity = CityLocation(
      displayName: _trip.destination,
      latitude: _trip.latitude ?? 0.0,
      longitude: _trip.longitude ?? 0.0,
    );
    DateTimeRange? selectedDates = DateTimeRange(start: _trip.startDate, end: _trip.endDate);
    String? selectedPurpose = _trip.purpose;
    final List<String> purposes = ['Vacation', 'Business', 'City Trip', 'Concert', 'Event', 'Skiing'];
    bool isLoadingWeather = false;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            title: const Text('Edit Trip'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Trip Name'),
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
                    initialValue: TextEditingValue(text: _trip.destination),
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
                        initialDateRange: selectedDates,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                        
                        WeatherForecast? weather;
                        // Only fetch weather if city or dates changed
                        if (selectedCity!.displayName != _trip.destination || 
                            selectedDates!.start != _trip.startDate || 
                            selectedDates!.end != _trip.endDate) {
                          weather = await _weatherService.fetchWeatherForTrip(
                            selectedCity!.latitude,
                            selectedCity!.longitude,
                            selectedDates!.start,
                            selectedDates!.end,
                          );
                        }

                        if(!context.mounted) return;
                        setStateBuilder(() => isLoadingWeather = false);
                        Navigator.pop(ctx, true);

                        _updateTrip(
                          titleController.text,
                          selectedCity!,
                          selectedDates!,
                          selectedPurpose ?? 'Vacation',
                          weather,
                        );
                      },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateTrip(
    String customTitle,
    CityLocation city,
    DateTimeRange dates,
    String purpose,
    WeatherForecast? weather,
  ) async {
    final title = customTitle.isNotEmpty ? customTitle : '${city.displayName.split(',')[0]} $purpose';
    
    // Update image only if destination changed
    String? imageUrl = _trip.imageUrl;
    if (city.displayName != _trip.destination) {
      imageUrl = _getDestinationImage(city.displayName);
    }

    final updatedTrip = _trip.copyWith(
      title: title,
      destination: city.displayName,
      startDate: dates.start,
      endDate: dates.end,
      weatherTemp: weather?.temperature ?? _trip.weatherTemp,
      weatherDescription: weather?.description ?? _trip.weatherDescription,
      purpose: purpose,
      latitude: city.latitude,
      longitude: city.longitude,
      imageUrl: imageUrl,
    );

    setState(() {
      _trip = updatedTrip;
    });

    final allTrips = StorageService.instance.getTrips();
    final index = allTrips.indexWhere((t) => t.id == _trip.id);
    if (index != -1) {
      allTrips[index] = _trip;
      await StorageService.instance.saveTrips(allTrips);
    }
  }

  Future<void> _generatePackingList() async {
    setState(() {
      _isGeneratingPackingList = true;
    });

    // Mock wardrobe for now, in a real app this comes from State/Provider
    final mockWardrobe = [
      WardrobeItem(id: 'w1', name: 'Silk Blouse', category: 'TOPS', imageUrl: '', createdAt: DateTime.now()),
      WardrobeItem(id: 'w2', name: 'Leather Trousers', category: 'BOTTOMS', imageUrl: '', createdAt: DateTime.now()),
      WardrobeItem(id: 'w3', name: 'Trench Coat', category: 'OUTERWEAR', imageUrl: '', createdAt: DateTime.now()),
    ];

    final suggestions = await _aiService.suggestPackingList(
      destination: _trip.destination,
      startDate: _trip.startDate,
      endDate: _trip.endDate,
      weatherDescription: _trip.weatherDescription,
      purpose: _trip.purpose,
      wardrobe: mockWardrobe,
    );

    if (suggestions != null && mounted) {
      final newItems = suggestions.map((s) {
        final matchId = s['id']?.toString();
        final match = mockWardrobe.cast<WardrobeItem?>().firstWhere(
           (w) => w!.id == matchId || w.name.toLowerCase() == s['name'].toString().toLowerCase(), 
           orElse: () => null
        );

        return PackingItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + s['name'],
          name: s['name'],
          category: s['category'],
          isPacked: false,
          isAIRecommended: s['isAIRecommended'] ?? true, // True if came from AI
          imageUrl: match?.imageUrl,
        );
      }).toList();

      setState(() {
        _trip = _trip.copyWith(packingList: newItems);
      });
      // Update this trip in the global storage
      final allTrips = StorageService.instance.getTrips();
      final index = allTrips.indexWhere((t) => t.id == _trip.id);
      if (index != -1) {
        allTrips[index] = _trip;
        await StorageService.instance.saveTrips(allTrips);
      }
    }

    if (mounted) {
      setState(() {
        _isGeneratingPackingList = false;
      });
    }
  }

  void _togglePacked(PackingItem item, bool? isPacked) {
    setState(() {
      final index = _trip.packingList.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final newList = List<PackingItem>.from(_trip.packingList);
        newList[index] = item.copyWith(isPacked: isPacked ?? false);
        _trip = _trip.copyWith(packingList: newList);
        
        final allTrips = StorageService.instance.getTrips();
        final tripIndex = allTrips.indexWhere((t) => t.id == _trip.id);
        if (tripIndex != -1) {
          allTrips[tripIndex] = _trip;
          StorageService.instance.saveTrips(allTrips);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: _editTrip,
            tooltip: 'Edit Trip',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: _deleteTrip,
            tooltip: 'Delete Trip',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTripCard(cs, theme),
                  const SizedBox(height: 32),
                  _buildAIRecommendations(cs, theme),
                  const SizedBox(height: 32),
                  _buildPackingList(cs, theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(ColorScheme cs, ThemeData theme) {
    final startStr = _trip.startDate.toLocal().toString().split(' ')[0];
    final endStr = _trip.endDate.toLocal().toString().split(' ')[0];

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(_trip.imageUrl ?? 'https://loremflickr.com/800/600/city'),
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
                  _trip.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_trip.destination} • $startStr to $endStr',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildWeatherStat(null, '${_trip.weatherTemp}', _trip.weatherDescription ?? 'Unknown'),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildAIRecommendations(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Packing Assistant',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.auto_awesome, color: cs.primary.withOpacity(0.2), size: 40),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Let AI generate a customized packing list based on your destination, weather, and wardrobe.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          _isGeneratingPackingList
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generatePackingList,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate Packing List'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPackingList(ColorScheme cs, ThemeData theme) {
    final packedCount = _trip.packingList.where((i) => i.isPacked).length;
    final totalCount = _trip.packingList.length;
    
    final categories = _trip.packingList.map((i) => i.category).toSet().toList();
    categories.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Packing List',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              '$packedCount / $totalCount ITEMS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Your list is empty. Use the AI Assistant or add items manually.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...categories.map((cat) {
            final items = _trip.packingList.where((i) => i.category == cat).toList();
            return _buildPackingCategory(cat, items, cs, theme, true);
          }).toList(),
      ],
    );
  }

  Widget _buildPackingCategory(String title, List<PackingItem> items, ColorScheme cs, ThemeData theme, bool expanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.4),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: cs.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
          if (expanded) ...items.map((i) => _buildPackingRow(i, cs, theme)).toList(),
          if (expanded && items.isEmpty) 
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('No items yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildPackingRow(PackingItem item, ColorScheme cs, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: item.isPacked,
              onChanged: (val) => _togglePacked(item, val),
              activeColor: const Color(0xFF5D634F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover),
              ),
            ),
          Expanded(
            child: Text(
              item.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: item.isPacked ? cs.onSurface.withOpacity(0.4) : cs.onSurface,
                decoration: item.isPacked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
