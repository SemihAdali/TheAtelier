import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final List<String> categories = ['All', 'Tops', 'Bottoms', 'Shoes', 'Accessories', 'Underwear'];
  String selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWardrobeItems();
  }

  Future<void> _fetchWardrobeItems() async {
    try {
      final response = await Supabase.instance.client
          .from('wardrobe_items')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          mockWardrobe = (response as List).map((i) => WardrobeItem.fromJson(i)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredItems = mockWardrobe.where((item) {
      final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;
      final query = _searchController.text.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ——— Header (Curation Profile) ———
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURATION PROFILE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elena Vance',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${mockWardrobe.length}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                                fontSize: 32,
                              ),
                            ),
                            Text(
                              'TOTAL PIECES',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.5,
                                fontSize: 8,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${mockOutfits.length}', 
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                                fontSize: 32,
                              ),
                            ),
                            Text(
                              'OUTFITS READY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.5,
                                fontSize: 8,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ——— Category Chips ———
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? colorScheme.onSurface.withOpacity(0.7) : colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cat,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected ? colorScheme.surface : colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),

                    // ——— Add New Item Card (Hero) ———
                    GestureDetector(
                      onTap: () async {
                        final needRefresh = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddItemScreen()));
                        if (needRefresh == true && mounted) _fetchWardrobeItems();
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Right side split color (mocking the image background in the screenshot)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Container(color: colorScheme.surfaceVariant.withOpacity(0.3)),
                            ),
                            
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.55,
                                    child: Text(
                                      'Expand your curated collection',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 16, color: colorScheme.surface),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Add New Item',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: colorScheme.surface,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Placeholder image overlay (representing the coat from the screenshot)
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(Icons.checkroom, size: 160, color: colorScheme.onSurface.withOpacity(0.05)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ——— Grid or Empty State ———
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredItems.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checkroom_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'Your wardrobe is empty.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your first piece.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredItems[index];
                      return _WardrobeItemCard(
                        item: item,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                          );
                          if (result == true) {
                            try {
                              await Supabase.instance.client
                                  .from('wardrobe_items')
                                  .delete()
                                  .eq('id', item.id);
                              if (item.imageUrl.startsWith('http')) {
                                final fileName = item.imageUrl.split('/').last;
                                await Supabase.instance.client.storage
                                    .from('wardrobe')
                                    .remove([fileName]);
                              }
                              if (mounted) setState(() { mockWardrobe.removeWhere((w) => w.id == item.id); });
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } else {
                            setState(() {});
                          }
                        },
                      );
                    },
                    childCount: filteredItems.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newItem = await Navigator.push<WardrobeItem>(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (newItem != null) setState(() { mockWardrobe.insert(0, newItem); });
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WardrobeItemCard extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback onTap;

  const _WardrobeItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ——— Image ———
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl.isNotEmpty
                  ? item.imageUrl.startsWith('http')
                      ? Image.network(item.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 32)))
                      : Image.file(File(item.imageUrl), fit: BoxFit.cover)
                  : Center(child: Icon(Icons.checkroom, size: 40, color: colorScheme.onSurface.withOpacity(0.2))),
            ),
          ),
          const SizedBox(height: 10),

          // ——— Labels ———
          if (item.brand != null && item.brand!.isNotEmpty)
            Text(
              item.brand!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: colorScheme.onSurface.withOpacity(0.45),
                fontSize: 9,
              ),
            ),
          Text(
            item.name,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.category,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
