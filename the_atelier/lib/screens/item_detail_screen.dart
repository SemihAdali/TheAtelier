import 'dart:io';
import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import 'add_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final WardrobeItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late WardrobeItem _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  void _onEdit() async {
    final updatedItem = await Navigator.push<WardrobeItem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(itemToEdit: _currentItem),
      ),
    );

    if (updatedItem != null) {
      setState(() {
        _currentItem = updatedItem;
      });
    }
  }

  void _onDelete() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to remove this item from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Close screen, return 'true' for deleted
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _onDelete,
            color: Colors.redAccent,
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Let the image bleed under the app bar
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 400,
              width: double.infinity,
              color: Colors.white,
              child: _currentItem.imageUrl.isNotEmpty
                  ? _currentItem.imageUrl.startsWith('http')
                      ? Image.network(
                          _currentItem.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 64),
                        )
                      : Image.file(
                          File(_currentItem.imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 64),
                        )
                  : const Icon(Icons.checkroom, size: 64),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentItem.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentItem.name,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Brand & Size row
                  Row(
                    children: [
                      if (_currentItem.brand != null && _currentItem.brand!.isNotEmpty) 
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BRAND', style: _labelStyle(context)),
                              const SizedBox(height: 4),
                              Text(_currentItem.brand!, style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                      if (_currentItem.size != null && _currentItem.size!.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SIZE', style: _labelStyle(context)),
                              const SizedBox(height: 4),
                              Text(_currentItem.size!, style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Tags
                  if (_currentItem.tags.isNotEmpty) ...[
                    Text('TAGS', style: _labelStyle(context)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _currentItem.tags.map((tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      letterSpacing: 1.2,
    );
  }
}
