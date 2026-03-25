import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'outfit_detail_screen.dart';
import '../models/outfit.dart';
import '../models/wardrobe_item.dart';
import '../models/wishlist_item.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

/// Normalize ISO 4217 currency codes to symbols.
String _currencySymbol(String? code) {
  final c = (code ?? '').trim().toUpperCase();
  if (c.isEmpty) return '€';
  switch (c) {
    case 'EUR': return '€';
    case 'USD': return r'$';
    case 'GBP': return '£';
    case 'CHF': return 'CHF';
    case 'JPY': return '¥';
    default: return code!;
  }
}

class OutfitDesignerScreen extends StatefulWidget {
  const OutfitDesignerScreen({super.key});

  @override
  State<OutfitDesignerScreen> createState() => _OutfitDesignerScreenState();
}

class _OutfitDesignerScreenState extends State<OutfitDesignerScreen>
    with SingleTickerProviderStateMixin {
  // Studio selections
  final List<WardrobeItem> _selectedWardrobe = [];
  final List<WishlistItem> _selectedWishlist = [];

  // Tab controller
  late final TabController _tabController;

  // Filter / search
  final TextEditingController _filterController = TextEditingController();

  // Wishlist data
  List<WishlistItem> _wishlist = [];
  bool _wishlistLoading = true;

  // AI Service
  final AIService _aiService = AIService();
  bool _isAiStyling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final response = await Supabase.instance.client
          .from('wishlist_items')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _wishlist = (response as List).map((i) => WishlistItem.fromJson(i)).toList();
          _wishlistLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  // ——— Studio actions ———

  void _toggleWardrobe(WardrobeItem item) {
    setState(() {
      if (_selectedWardrobe.contains(item)) {
        _selectedWardrobe.remove(item);
      } else {
        _selectedWardrobe.add(item);
      }
    });
  }

  void _toggleWishlist(WishlistItem item) {
    setState(() {
      if (_selectedWishlist.contains(item)) {
        _selectedWishlist.remove(item);
      } else {
        _selectedWishlist.add(item);
      }
    });
  }

  bool get _hasSelection => _selectedWardrobe.isNotEmpty || _selectedWishlist.isNotEmpty;
  int get _totalSelected => _selectedWardrobe.length + _selectedWishlist.length;

  void _clearStudio() {
    setState(() {
      _selectedWardrobe.clear();
      _selectedWishlist.clear();
    });
  }

  Future<void> _generateAiOutfit() async {
    setState(() => _isAiStyling = true);
    
    try {
      final suggestion = await _aiService.suggestOutfit(
        wardrobe: mockWardrobe,
        wishlist: _wishlist,
      );

      if (suggestion != null && mounted) {
        setState(() {
          // Clear current selection and apply AI suggestion
          _selectedWardrobe.clear();
          _selectedWishlist.clear();

          for (final id in suggestion.wardrobeItemIds) {
            final item = mockWardrobe.cast<WardrobeItem?>().firstWhere((i) => i?.id == id, orElse: () => null);
            if (item != null) _selectedWardrobe.add(item);
          }

          for (final id in suggestion.wishlistItemIds) {
            final item = _wishlist.cast<WishlistItem?>().firstWhere((i) => i?.id == id, orElse: () => null);
            if (item != null) _selectedWishlist.add(item);
          }
          
          _isAiStyling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ AI Stylist: ${suggestion.justification}'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() => _isAiStyling = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAiStyling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: $e')),
        );
      }
    }
  }

  Future<void> _saveOutfit() async {
    if (!_hasSelection) return;

    final nameController = TextEditingController(
      text: 'Composition ${(_totalSelected > 0 ? mockOutfits.length + 1 : 1).toString().padLeft(2, '0')}',
    );
    final occasionController = TextEditingController(text: '');

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Name Your Outfit',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx, false)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$_totalSelected piece${_totalSelected == 1 ? '' : 's'} selected',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 16),
            _sheetField(ctx, controller: nameController, label: 'Outfit Name'),
            const SizedBox(height: 12),
            _sheetField(ctx, controller: occasionController, label: 'Occasion / Season (optional)'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save to Lookbook'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final newOutfit = Outfit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'Untitled Outfit',
        occasion: occasionController.text.trim().isNotEmpty ? occasionController.text.trim() : null,
        items: _selectedWardrobe.map((e) => e.id).toList(),
        wishlistItems: _selectedWishlist.map((e) => e.id).toList(),
        createdAt: DateTime.now(),
      );

      await StorageService.instance.addOutfit(newOutfit);

      setState(() {
        mockOutfits.insert(0, newOutfit);
        _selectedWardrobe.clear();
        _selectedWishlist.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newOutfit.name} saved beautifully.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _sheetField(BuildContext context, {required TextEditingController controller, required String label}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.primary)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // ——— Filtered lists ———

  List<WardrobeItem> get _filteredWardrobe {
    final q = _filterController.text.toLowerCase().trim();
    if (q.isEmpty) return mockWardrobe;
    return mockWardrobe.where((i) =>
        i.name.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q) ||
        (i.brand?.toLowerCase().contains(q) ?? false) ||
        i.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  List<WishlistItem> get _filteredWishlist {
    final q = _filterController.text.toLowerCase().trim();
    if (q.isEmpty) return _wishlist;
    return _wishlist.where((i) =>
        i.productName.toLowerCase().contains(q) ||
        (i.brand?.toLowerCase().contains(q) ?? false)).toList();
  }

  // ——— Studio canvas items (mixed) ———
  // Combine both selections into one flat list for the canvas display
  List<_CanvasItem> get _canvasItems => [
        ..._selectedWardrobe.map((w) => _CanvasItem(
              imageUrl: w.imageUrl,
              name: w.name,
              onRemove: () => _toggleWardrobe(w),
            )),
        ..._selectedWishlist.map((wl) => _CanvasItem(
              imageUrl: wl.imageUrl ?? '',
              name: wl.productName,
              onRemove: () => _toggleWishlist(wl),
              isWishlist: true,
            )),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canvas = _canvasItems;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ——— Header ———
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREATIVE SUITE',
                      style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: cs.primary.withOpacity(0.6))),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Designer', 
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasSelection) ...[
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: cs.surfaceVariant,
                                foregroundColor: cs.onSurface,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _clearStudio,
                              child: const Text('Clear', style: TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // ——— AI Stylist Button ———
                          IconButton(
                            onPressed: _isAiStyling ? null : _generateAiOutfit,
                            icon: _isAiStyling 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: cs.primaryContainer.withOpacity(0.3),
                              foregroundColor: cs.primary,
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(36, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            constraints: const BoxConstraints(),
                            tooltip: 'AI Style',
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: _hasSelection ? _saveOutfit : null,
                            child: Text(
                              _hasSelection ? 'Save ($_totalSelected)' : 'Save',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

              // ——— Tabs ———
              Row(
                children: [
                  _TabButton(
                    label: 'My Wardrobe',
                    isActive: _tabController.index == 0,
                    onTap: () => _tabController.animateTo(0),
                    badgeCount: _selectedWardrobe.length,
                    primaryColor: cs.primary,
                    theme: theme,
                  ),
                  const SizedBox(width: 24),
                  _TabButton(
                    label: 'Wishlist',
                    isActive: _tabController.index == 1,
                    onTap: () => _tabController.animateTo(1),
                    badgeCount: _selectedWishlist.length,
                    primaryColor: cs.primary,
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ——— Filter ———
              TextField(
                controller: _filterController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _tabController.index == 0
                      ? 'Filter wardrobe by name, category or tag...'
                      : 'Filter wishlist by name or brand...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.tune, size: 18, color: cs.onSurface.withOpacity(0.4)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.primary)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _filterController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { _filterController.clear(); setState(() {}); })
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // ——— Tab Content: Wardrobe Grid ———
              if (_tabController.index == 0) ...[
                if (_filteredWardrobe.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No items match "${_filterController.text}"',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.4)))),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredWardrobe.length,
                    itemBuilder: (_, i) {
                      final item = _filteredWardrobe[i];
                      final isSelected = _selectedWardrobe.contains(item);
                      return _ItemGridCard(
                        imageUrl: item.imageUrl,
                        name: item.name,
                        subtitle: item.category,
                        topLabel: item.brand,
                        isSelected: isSelected,
                        onTap: () => _toggleWardrobe(item),
                        primaryColor: cs.primary,
                        onPrimary: cs.onPrimary,
                        surfaceColor: cs.surface,
                        theme: theme,
                      );
                    },
                  ),
              ],

              // ——— Tab Content: Wishlist Grid ———
              if (_tabController.index == 1) ...[
                if (_wishlistLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredWishlist.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.favorite_border, size: 40, color: cs.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          _filterController.text.isNotEmpty
                              ? 'No items match "${_filterController.text}"'
                              : 'Your wishlist is empty.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.4)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredWishlist.length,
                    itemBuilder: (_, i) {
                      final item = _filteredWishlist[i];
                      final isSelected = _selectedWishlist.contains(item);
                      return _ItemGridCard(
                        imageUrl: item.imageUrl ?? '',
                        name: item.productName,
                        subtitle: item.brand ?? 'Wishlist',
                        topLabel: item.brand,
                        isSelected: isSelected,
                        onTap: () => _toggleWishlist(item),
                        primaryColor: cs.primary,
                        onPrimary: cs.onPrimary,
                        surfaceColor: cs.surface,
                        theme: theme,
                        badge: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.price != null
                                ? '${item.price!.toStringAsFixed(2)} ${_currencySymbol(item.currency)}'
                                : 'Wishlist',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: cs.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 48),

              // ——— Studio Canvas ———
              Container(
                width: double.infinity,
                height: 420,
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(32)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Watermark
                    Text('STUDIO',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 80,
                          color: cs.onSurface.withOpacity(0.04),
                          letterSpacing: -2,
                        )),

                    // Empty hint
                    if (canvas.isEmpty)
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_circle_outline, size: 36, color: cs.onSurface.withOpacity(0.15)),
                        const SizedBox(height: 8),
                        Text('Tap items above to compose',
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.3))),
                      ]),

                    // Stacked item cards
                    ...canvas.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ci = entry.value;
                      double dx = (idx % 2 == 0) ? -40.0 : 40.0;
                      if (idx == 0) dx = 0;
                      final dy = -80.0 + (60.0 * idx);

                      return Positioned(
                        top: 80 + dy,
                        left: MediaQuery.of(context).size.width / 2 - 90 + dx,
                        child: GestureDetector(
                          onTap: ci.onRemove,
                          child: Transform.rotate(
                            angle: (idx % 2 == 0 ? -0.06 : 0.04) * (idx + 1),
                            child: Container(
                              width: 120,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8))],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: ci.imageUrl.isNotEmpty
                                          ? Image.network(ci.imageUrl, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Center(child: Icon(Icons.checkroom, color: Colors.grey[300])))
                                          : Center(
                                              child: Text(ci.name[0].toUpperCase(),
                                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey)),
                                            ),
                                    ),
                                  ),
                                  // Wishlist badge
                                  if (ci.isWishlist)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                                        child: Icon(Icons.favorite, size: 10, color: cs.primary),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    if (canvas.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        child: Text('TAP AN ITEM TO REMOVE',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9, letterSpacing: 2, color: cs.onSurface.withOpacity(0.3),
                            )),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 64),

              const SizedBox(height: 64),

              // ——— Saved Outfits ———
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Outfits', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                  if (mockOutfits.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitDetailScreen(outfit: mockOutfits.first))),
                      child: Text('View Lookbook', style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (mockOutfits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.style_outlined, size: 36, color: cs.onSurface.withOpacity(0.2)),
                    const SizedBox(height: 8),
                    Text('No outfits saved yet.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.45))),
                    Text('Select items and tap "Save Outfit".',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.3))),
                  ]),
                )
              else
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mockOutfits.length,
                    itemBuilder: (_, i) {
                      final outfit = mockOutfits[i];
                      // Collect wardrobe images first, then wishlist images for the preview grid
                      final outfitWardrobeItems = mockWardrobe.where((w) => outfit.items.contains(w.id)).toList();
                      final outfitWishlistItems = _wishlist.where((wl) => outfit.wishlistItems.contains(wl.id)).toList();
                      // Merge into a flat list of image URLs (wardrobe first, then wishlist)
                      final previewImages = [
                        ...outfitWardrobeItems.map((w) => w.imageUrl),
                        ...outfitWishlistItems.map((wl) => wl.imageUrl ?? '').where((url) => url.isNotEmpty),
                      ];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitDetailScreen(outfit: outfit))),
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.all(8),
                                child: previewImages.isEmpty
                                    // Placeholder grid if no images available
                                    ? Row(children: [
                                        Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                                        const SizedBox(width: 8),
                                        Expanded(child: Column(children: [
                                          Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                                          const SizedBox(height: 8),
                                          Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                                        ])),
                                      ])
                                    : previewImages.length == 1
                                        ? ClipRRect(borderRadius: BorderRadius.circular(8),
                                            child: Image.network(previewImages[0], fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(color: Colors.white)))
                                        : Row(children: [
                                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                                                child: Image.network(previewImages[0], fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(color: Colors.white)))),
                                            const SizedBox(width: 8),
                                            Expanded(child: Column(children: [
                                              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(previewImages[1], fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(color: Colors.white)))),
                                              if (previewImages.length > 2) ...[
                                                const SizedBox(height: 8),
                                                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(previewImages[2], fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Container(color: Colors.white)))),
                                              ],
                                            ])),
                                          ]),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(outfit.name.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 10),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              '${outfit.totalPieces} piece${outfit.totalPieces == 1 ? '' : 's'}${outfit.occasion != null ? ' • ${outfit.occasion}' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: cs.onSurface.withOpacity(0.5)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ——— Helper data class for mixed studio canvas items ———
class _CanvasItem {
  final String imageUrl;
  final String name;
  final VoidCallback onRemove;
  final bool isWishlist;

  const _CanvasItem({
    required this.imageUrl,
    required this.name,
    required this.onRemove,
    this.isWishlist = false,
  });
}

// ——— Reusable item grid card ———
class _ItemGridCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String subtitle;
  final String? topLabel; // brand name shown above the product name
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color onPrimary;
  final Color surfaceColor;
  final ThemeData theme;
  final Widget? badge;

  const _ItemGridCard({
    required this.imageUrl,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.onPrimary,
    required this.surfaceColor,
    required this.theme,
    this.topLabel,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: primaryColor, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.checkroom, size: 36, color: Colors.grey[300])))
                      : Center(child: Icon(Icons.checkroom, size: 36, color: Colors.grey[300])),
                  if (isSelected)
                    Container(
                      color: primaryColor.withOpacity(0.1),
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        child: Icon(Icons.check, size: 12, color: onPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Brand eyebrow label (editorial style — tiny, uppercase, letter-spaced)
          if (topLabel != null && topLabel!.isNotEmpty)
            Text(
              topLabel!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.grey.withOpacity(0.55),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(name.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          badge ?? Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey.withOpacity(0.7))),
        ],
      ),
    );
  }
}

// ——— Animated tab button ———
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;
  final Color primaryColor;
  final ThemeData theme;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.badgeCount,
    required this.primaryColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? null : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
