import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/outfit.dart';
import '../models/wardrobe_item.dart';
import '../models/wishlist_item.dart';

/// Normalize ISO 4217 currency codes (or empty values) to symbols.
String _detailCurrencySymbol(String? code) {
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

class OutfitDetailScreen extends StatefulWidget {
  final Outfit outfit;

  const OutfitDetailScreen({super.key, required this.outfit});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  List<WishlistItem> _wishlistItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlistItems();
  }

  Future<void> _loadWishlistItems() async {
    if (widget.outfit.wishlistItems.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('wishlist_items')
          .select()
          .inFilter('id', widget.outfit.wishlistItems);
      if (mounted) {
        setState(() {
          _wishlistItems = (response as List).map((i) => WishlistItem.fromJson(i)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Wardrobe items for this outfit
    final wardrobeItems = mockWardrobe.where((i) => widget.outfit.items.contains(i.id)).toList();

    // All canvas items: wardrobe first, then wishlist
    final allImages = [
      ...wardrobeItems.map((w) => w.imageUrl),
      ..._wishlistItems.map((wl) => wl.imageUrl ?? '').where((u) => u.isNotEmpty),
    ];

    final totalPieces = widget.outfit.totalPieces;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ——— App Bar ———
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // ——— Header ———
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.outfit.occasion?.toUpperCase() ?? 'COMPOSITION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: cs.primary.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.outfit.name,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalPieces piece${totalPieces == 1 ? '' : 's'} • ${widget.outfit.createdAt.day}.${widget.outfit.createdAt.month}.${widget.outfit.createdAt.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ——— Studio Canvas (all items stacked) ———
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  height: 420,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : allImages.isEmpty
                          ? Center(
                              child: Text('No items found',
                                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.3))),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                // Watermark
                                Text('LOOKBOOK',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 60,
                                      color: cs.onSurface.withOpacity(0.035),
                                      letterSpacing: -2,
                                    )),

                                ...allImages.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final url = entry.value;
                                  double dx = (idx % 2 == 0) ? -30.0 : 30.0;
                                  if (idx == 0) dx = 0;
                                  final dy = -80.0 + (60.0 * idx);
                                  // Is this a wishlist item? (index >= wardrobeItems.length)
                                  final isWishlist = idx >= wardrobeItems.length;

                                  return Positioned(
                                    top: 100 + dy,
                                    left: MediaQuery.of(context).size.width / 2 - 100 + dx,
                                    child: Transform.rotate(
                                      angle: (idx % 2 == 0 ? -0.06 : 0.04) * (idx + 1),
                                      child: Container(
                                        width: 140,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(url, fit: BoxFit.cover,
                                                  width: double.infinity, height: double.infinity,
                                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
                                            ),
                                            // ❤️ badge for wishlist items
                                            if (isWishlist)
                                              Positioned(
                                                top: 4, right: 4,
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
                                  );
                                }),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 40),

              // ——— Items List ———
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Constituent Items',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // Wardrobe items
              if (wardrobeItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FROM WARDROBE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            color: cs.onSurface.withOpacity(0.4),
                            fontSize: 9,
                          )),
                      const SizedBox(height: 8),
                      ...wardrobeItems.map((item) => _ItemRow(
                            imageUrl: item.imageUrl,
                            name: item.name,
                            subtitle: item.category,
                            badge: item.brand,
                            cs: cs,
                            theme: theme,
                          )),
                    ],
                  ),
                ),

              // Wishlist items
              if (_wishlistItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FROM WISHLIST',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.5,
                            color: cs.primary.withOpacity(0.5),
                            fontSize: 9,
                          )),
                      const SizedBox(height: 8),
                      ..._wishlistItems.map((item) => _ItemRow(
                            imageUrl: item.imageUrl ?? '',
                            name: item.productName,
                            subtitle: item.brand ?? '',
                            badge: item.price != null
                                ? '${item.price!.toStringAsFixed(2)} ${_detailCurrencySymbol(item.currency)}'
                                : null,
                            isWishlist: true,
                            linkUrl: item.linkUrl,
                            cs: cs,
                            theme: theme,
                          )),
                    ],
                  ),
                ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single row entry in the items list.
class _ItemRow extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String subtitle;
  final String? badge;
  final bool isWishlist;
  final String? linkUrl;
  final ColorScheme cs;
  final ThemeData theme;

  const _ItemRow({
    required this.imageUrl,
    required this.name,
    required this.subtitle,
    required this.cs,
    required this.theme,
    this.badge,
    this.isWishlist = false,
    this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWishlist
              ? cs.primary.withOpacity(0.2)
              : cs.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: cs.surface),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]))
                : Center(child: Icon(isWishlist ? Icons.favorite_border : Icons.checkroom,
                    color: cs.onSurface.withOpacity(0.3))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                      child: Text(badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.7),
                          )),
                    ),
                  ),
              ],
            ),
          ),
          if (isWishlist && linkUrl != null && linkUrl!.isNotEmpty)
            IconButton(
              icon: Icon(Icons.arrow_outward, size: 18, color: cs.primary),
              onPressed: () async {
                final uri = Uri.tryParse(linkUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            )
          else
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
