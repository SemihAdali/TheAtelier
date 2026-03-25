import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wishlist_item.dart';
import '../models/wardrobe_item.dart';
import 'add_item_screen.dart';

class WishlistItemDetailScreen extends StatefulWidget {
  final WishlistItem item;

  const WishlistItemDetailScreen({super.key, required this.item});

  @override
  State<WishlistItemDetailScreen> createState() => _WishlistItemDetailScreenState();
}

class _WishlistItemDetailScreenState extends State<WishlistItemDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _sizeController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.productName);
    _brandController = TextEditingController(text: widget.item.brand ?? '');
    _sizeController = TextEditingController(text: widget.item.size ?? '');
    _priceController = TextEditingController(text: widget.item.price?.toStringAsFixed(2) ?? '');
    _imageController = TextEditingController(text: widget.item.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _launchURL() async {
    final uri = Uri.parse(widget.item.linkUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch shop link')));
      }
    }
  }

  Future<void> _updateItem() async {
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'product_name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'size': _sizeController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()),
        'image_url': _imageController.text.trim(),
      };

      final response = await Supabase.instance.client
          .from('wishlist_items')
          .update(updatedData)
          .eq('id', widget.item.id)
          .select()
          .single();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        Navigator.pop(context, WishlistItem.fromJson(response));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to remove this item from your wishlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('wishlist_items')
            .delete()
            .eq('id', widget.item.id);
            
        if (mounted) {
          Navigator.pop(context, 'deleted');
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          filled: _isEditing,
          fillColor: _isEditing ? Theme.of(context).colorScheme.surfaceVariant : Colors.transparent,
          border: _isEditing ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none) : UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current display image derived from controller so it updates immediately during edit
    final currentImage = _imageController.text.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in Shop',
            onPressed: _launchURL,
          ),
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.checkroom),
              tooltip: 'Move to Wardrobe',
              onPressed: () async {
                final newItem = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddItemScreen(wishlistItemToTransfer: widget.item),
                  ),
                );
                if (newItem != null && mounted) {
                  try {
                    await Supabase.instance.client
                        .from('wishlist_items')
                        .delete()
                        .eq('id', widget.item.id);
                    
                    mockWardrobe.insert(0, newItem as WardrobeItem);
                    
                    if (mounted) {
                      Navigator.pop(context, 'deleted');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Wardrobe!')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete from wishlist: $e')));
                    }
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Item',
              onPressed: () => setState(() => _isEditing = true),
            ),
          ] else
            IconButton(
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _updateItem,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Header
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              color: Colors.white,
              child: currentImage.isNotEmpty
                  ? Image.network(
                      currentImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Product Name', _nameController),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Brand', _brandController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Size', _sizeController)),
                    ],
                  ),
                  _buildTextField('Price (${widget.item.currency ?? 'EUR'})', _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  if (_isEditing) _buildTextField('Image URL', _imageController),
                  
                  const SizedBox(height: 32),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove from Wishlist'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: _deleteItem,
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Go to Shop'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _launchURL,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
