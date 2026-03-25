import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wishlist_item.dart';
import 'wishlist_item_detail_screen.dart';
import 'webview_scanner_screen.dart';

/// Normalize ISO 4217 currency codes to symbols.
String _wishlistCurrencySymbol(String? code) {
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

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  bool _isDiscerning = false;
  List<WishlistItem> _wishlist = [];

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    try {
      final response = await Supabase.instance.client
          .from('wishlist_items')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _wishlist = (response as List).map((i) => WishlistItem.fromJson(i)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load wishlist: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  static double? _parsePrice(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (RegExp(r'[0-9],[0-9]{2}$').hasMatch(s)) {
      return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    if (RegExp(r'[0-9]\.[0-9]{2}$').hasMatch(s)) {
      return double.tryParse(s.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  Future<void> _discernProduct() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebViewScannerScreen(url: url), fullscreenDialog: true),
    );

    var data = <String, dynamic>{
      'product_name': '',
      'price': null,
      'currency': 'EUR',
      'image_url': '',
      'brand': '',
      'size': '',
    };

    if (result != null && result is Map<String, dynamic>) {
      if (result['title'] != null) data['product_name'] = result['title'];
      if (result['image'] != null) data['image_url'] = result['image'];
      if (result['brand'] != null) data['brand'] = result['brand'];
      if (result['currency'] != null) data['currency'] = result['currency'];
      if (result['price'] != null) data['price'] = _parsePrice(result['price'].toString());
    }

    _urlController.clear();
    if (mounted) _showConfirmationDialog(data, url);
  }

  void _showConfirmationDialog(Map<String, dynamic> data, String originalUrl) {
    final titleController = TextEditingController(text: data['product_name']);
    final priceController = TextEditingController(text: (data['price'] as double?)?.toStringAsFixed(2) ?? '');
    final brandController = TextEditingController(text: data['brand']);
    final sizeController = TextEditingController(text: data['size']);
    final imageController = TextEditingController(text: data['image_url']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add to Wishlist', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data['image_url'] != null && data['image_url'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(data['image_url'], height: 160, width: double.infinity, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50)),
                ),
              const SizedBox(height: 16),
              _buildFormField(ctx, controller: titleController, label: 'Product Name'),
              const SizedBox(height: 12),
              _buildFormField(ctx, controller: brandController, label: 'Brand'),
              const SizedBox(height: 12),
              _buildFormField(ctx, controller: sizeController, label: 'Size'),
              const SizedBox(height: 12),
              _buildFormField(ctx, controller: priceController, label: 'Price (${data['currency'] ?? 'EUR'})', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveToWishlist(
                      titleController.text,
                      double.tryParse(priceController.text),
                      data['currency'] ?? 'EUR',
                      imageController.text,
                      brandController.text,
                      sizeController.text,
                      originalUrl,
                    );
                  },
                  child: const Text('Save to Wishlist'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(BuildContext context, {required TextEditingController controller, required String label, TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Future<void> _saveToWishlist(String name, double? price, String currency, String? imageUrl, String? brand, String? size, String linkUrl) async {
    try {
      final response = await Supabase.instance.client
          .from('wishlist_items')
          .insert({
            'product_name': name,
            'price': price,
            'currency': currency,
            'image_url': imageUrl ?? '',
            'brand': brand,
            'size': size,
            'link_url': linkUrl,
          })
          .select()
          .single();
      setState(() {
        _wishlist.insert(0, WishlistItem.fromJson(response));
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  Future<void> _deleteItem(WishlistItem item) async {
    try {
      await Supabase.instance.client.from('wishlist_items').delete().eq('id', item.id);
      setState(() { _wishlist.removeWhere((i) => i.id == item.id); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ——— Main Content ———
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ——— URL Input ———
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Paste shop link here...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.35),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _isDiscerning ? null : _discernProduct,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isDiscerning
                              ? SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                                )
                              : Icon(Icons.auto_awesome, color: colorScheme.onPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ——— List / Empty State ———
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _wishlist.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'Your wishlist is empty.',
                                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paste a link to start tracking.',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.3)),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: _wishlist.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withOpacity(0.25),
                          ),
                          itemBuilder: (context, index) {
                            final item = _wishlist[index];
                            return _WishlistItemRow(
                              item: item,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => WishlistItemDetailScreen(item: item)),
                                );
                                if (result == 'deleted') {
                                  setState(() { _wishlist.removeWhere((i) => i.id == item.id); });
                                } else if (result is WishlistItem) {
                                  setState(() {
                                    final idx = _wishlist.indexWhere((i) => i.id == item.id);
                                    if (idx != -1) _wishlist[idx] = result;
                                  });
                                }
                              },
                              onDelete: () => _deleteItem(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistItemRow extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WishlistItemRow({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 72,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)))
                  : Center(child: Icon(Icons.favorite_border, color: colorScheme.onSurface.withOpacity(0.2))),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.brand != null && item.brand!.isNotEmpty)
                    Text(
                      item.brand!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: colorScheme.onSurface.withOpacity(0.45),
                        fontSize: 9,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    item.productName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.size != null && item.size!.isNotEmpty)
                    Text(
                      'Size: ${item.size}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (item.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.price!.toStringAsFixed(2)} ${_wishlistCurrencySymbol(item.currency)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Visit Store Button
            if (item.linkUrl.isNotEmpty)
              IconButton(
                icon: Icon(Icons.arrow_outward, size: 18, color: colorScheme.primary),
                onPressed: () async {
                  final uri = Uri.tryParse(item.linkUrl);
                  if (uri != null && await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
          ],
        ),
      ),
    );
  }
}
