import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wardrobe_item.dart';
import '../models/wishlist_item.dart';

class AddItemScreen extends StatefulWidget {
  final WardrobeItem?
  itemToEdit; // Optional: If provided, we are editing an existing item
  final WishlistItem?
  wishlistItemToTransfer; // Optional: If provided, we are pre-filling from a wishlist item

  const AddItemScreen({
    super.key,
    this.itemToEdit,
    this.wishlistItemToTransfer,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _sizeController;
  late TextEditingController _tagsController;

  String _selectedCategory = 'Tops';
  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Shoes',
    'Accessories',
    'Underwear',
  ];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if editing, or empty if creating
    _nameController = TextEditingController(
      text:
          widget.itemToEdit?.name ??
          widget.wishlistItemToTransfer?.productName ??
          '',
    );
    _brandController = TextEditingController(
      text:
          widget.itemToEdit?.brand ??
          widget.wishlistItemToTransfer?.brand ??
          '',
    );
    _sizeController = TextEditingController(
      text:
          widget.itemToEdit?.size ?? widget.wishlistItemToTransfer?.size ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.itemToEdit?.tags.join(', ') ?? '',
    );

    if (widget.itemToEdit != null) {
      _selectedCategory = widget.itemToEdit!.category;
      if (widget.itemToEdit!.imageUrl.isNotEmpty) {
        _imageFile = File(widget.itemToEdit!.imageUrl);
      }
    } else if (widget.wishlistItemToTransfer != null) {
      if (widget.wishlistItemToTransfer!.imageUrl != null &&
          widget.wishlistItemToTransfer!.imageUrl!.isNotEmpty) {
        _imageFile = File(widget.wishlistItemToTransfer!.imageUrl!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      // Show loading
      setState(() {
        _isLoading = true;
      });

      try {
        List<String> parsedTags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        String finalImageUrl =
            widget.itemToEdit?.imageUrl ??
            widget.wishlistItemToTransfer?.imageUrl ??
            '';

        // Check if we selected a new local image
        // If imageFile path doesn't start with http, it's local and needs upload
        if (!_imageFile!.path.startsWith('http')) {
          final extension = _imageFile!.path.split('.').last;
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}.$extension';

          await Supabase.instance.client.storage
              .from('wardrobe')
              .upload(fileName, _imageFile!);

          finalImageUrl = Supabase.instance.client.storage
              .from('wardrobe')
              .getPublicUrl(fileName);
        }

        if (widget.itemToEdit != null) {
          // Update existing item
          final updatedData = {
            'name': _nameController.text,
            'category': _selectedCategory,
            'brand': _brandController.text.isNotEmpty
                ? _brandController.text
                : null,
            'size': _sizeController.text.isNotEmpty
                ? _sizeController.text
                : null,
            'tags': parsedTags,
            'image_url': finalImageUrl,
          };

          final response = await Supabase.instance.client
              .from('wardrobe_items')
              .update(updatedData)
              .eq('id', widget.itemToEdit!.id)
              .select()
              .single();

          if (mounted) {
            Navigator.pop(context, WardrobeItem.fromJson(response));
          }
        } else {
          // Create new item
          final newItemData = {
            'name': _nameController.text,
            'category': _selectedCategory,
            'brand': _brandController.text.isNotEmpty
                ? _brandController.text
                : null,
            'size': _sizeController.text.isNotEmpty
                ? _sizeController.text
                : null,
            'tags': parsedTags,
            'image_url': finalImageUrl,
          };

          final response = await Supabase.instance.client
              .from('wardrobe_items')
              .insert(newItemData)
              .select()
              .single();

          if (mounted) {
            Navigator.pop(context, WardrobeItem.fromJson(response));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving item: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo from camera or gallery.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Item', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Area (No borders, just a surface shift)
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take a photo'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: _imageFile!.path.startsWith('http')
                                ? NetworkImage(_imageFile!.path)
                                      as ImageProvider
                                : FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add photo',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 32),

              // Item Name Input (Ghost border style)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Garment Name',
                  hintText: 'e.g. Vintage Denim Jacket',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 24),

              // Brand Input
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  hintText: 'e.g. Zara, Acne Studios',
                ),
              ),
              const SizedBox(height: 24),

              // Size Input
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size',
                  hintText: 'e.g. M, 32/34, One Size',
                ),
              ),
              const SizedBox(height: 24),

              // Tags Input
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'e.g. summer, casual, favorite',
                ),
              ),
              const SizedBox(height: 32),

              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),

              // Category Selection
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.itemToEdit != null
                              ? 'Save Changes'
                              : 'Add to Wardrobe',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
