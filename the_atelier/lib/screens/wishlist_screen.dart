import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_item.dart';
import 'wishlist_item_detail_screen.dart';
import 'webview_scanner_screen.dart';

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

  /// Parses price strings from shops — handles European comma-decimal
  /// (99,95 → 99.95), dot-decimal (99.95), and thousands separators
  /// (1.299,00 → 1299.00, 1,299.00 → 1299.00).
  static double? _parsePrice(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    // European: ends with comma + 2 digits → decimal comma
    if (RegExp(r'[0-9],[0-9]{2}$').hasMatch(s)) {
      return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    // US / standard: ends with dot + 2 digits → decimal dot
    if (RegExp(r'[0-9]\.[0-9]{2}$').hasMatch(s)) {
      return double.tryParse(s.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    // Fallback: strip everything except digits and dot
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  Future<void> _discernProduct() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    // Unfocus keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScannerScreen(url: url),
        fullscreenDialog: true,
      ),
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
       if (result['price'] != null) {
          data['price'] = _parsePrice(result['price'].toString());
       }
    }

    _urlController.clear();
    _showConfirmationDialog(data, url);
  }

  void _showConfirmationDialog(Map<String, dynamic> data, String originalUrl) {
    final titleController = TextEditingController(text: data['product_name']);
    final priceController = TextEditingController(text: (data['price'] as double?)?.toStringAsFixed(2) ?? '');
    final brandController = TextEditingController(text: data['brand']);
    final sizeController = TextEditingController(text: data['size']);
    final imageController = TextEditingController(text: data['image_url']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Add to Wishlist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['image_url'] != null && data['image_url'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['image_url'],
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: brandController,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sizeController,
                decoration: InputDecoration(
                  labelText: 'Size',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price (${data['currency'] ?? 'EUR'})',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: InputBorder.none,
                ),
              ),
              // Image URL text field removed as requested
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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
            child: const Text('Save'),
          ),
        ],
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
      await Supabase.instance.client
          .from('wishlist_items')
          .delete()
          .eq('id', item.id);
          
      setState(() {
        _wishlist.removeWhere((i) => i.id == item.id);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wishlist',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Input Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Paste shop link here...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isDiscerning ? null : _discernProduct,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: _isDiscerning
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                ),
              ],
            ),
          ),

          // Grid Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _wishlist.isEmpty
                    ? Center(
                        child: Text(
                          'Your wishlist is empty.\nPaste a link to start dreaming.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _wishlist.length,
                        itemBuilder: (context, index) {
                          final item = _wishlist[index];
                          return Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceContainerLowest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WishlistItemDetailScreen(item: item),
                                  ),
                                );
                                if (result == 'deleted') {
                                  setState(() {
                                    _wishlist.removeWhere((i) => i.id == item.id);
                                  });
                                } else if (result is WishlistItem) {
                                  setState(() {
                                    final index = _wishlist.indexWhere((i) => i.id == item.id);
                                    if (index != -1) _wishlist[index] = result;
                                  });
                                }
                              },
                              onLongPress: () => _deleteItem(item),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      ),
                                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl!,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image, size: 40),
                                            )
                                          : const Icon(Icons.image, size: 40),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item.brand != null && item.brand!.isNotEmpty)
                                          Text(
                                            item.brand!.toUpperCase(),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.productName,
                                          style: Theme.of(context).textTheme.titleSmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (item.size != null && item.size!.isNotEmpty)
                                          Text(
                                            'Size: ${item.size}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        const SizedBox(height: 4),
                                        if (item.price != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.price!.toStringAsFixed(2)} ${item.currency ?? ''}',
                                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
