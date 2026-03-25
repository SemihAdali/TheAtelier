import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/wardrobe_item.dart';
import '../models/wishlist_item.dart';

class AISuggestion {
  final String name;
  final List<String> wardrobeItemIds;
  final List<String> wishlistItemIds;
  final String justification;

  AISuggestion({
    required this.name,
    required this.wardrobeItemIds,
    required this.wishlistItemIds,
    required this.justification,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      name: json['name'] as String? ?? 'New Outfit',
      wardrobeItemIds: List<String>.from(json['wardrobe_item_ids'] ?? []),
      wishlistItemIds: List<String>.from(json['wishlist_item_ids'] ?? []),
      justification: json['justification'] as String? ?? '',
    );
  }
}

class AIService {
  // TODO: Replace with secure storage or environment variable
  static const String _apiKey = 'REPLACE_WITH_YOUR_GEMINI_API_KEY';

  final GenerativeModel _model;

  AIService()
    : _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

  Future<AISuggestion?> suggestOutfit({
    required List<WardrobeItem> wardrobe,
    required List<WishlistItem> wishlist,
    String? mood,
  }) async {
    if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      // Mock fallback for UI testing if no key is provided
      await Future.delayed(const Duration(seconds: 2));
      return AISuggestion(
        name: 'Midnight Editorial',
        wardrobeItemIds: wardrobe.take(3).map((e) => e.id).toList(),
        wishlistItemIds: wishlist.isNotEmpty ? [wishlist.first.id] : [],
        justification:
            "A sophisticated blend of your most iconic pieces for a timeless evening look.",
      );
    }

    final wardrobeContext = wardrobe
        .map(
          (i) =>
              'ID: ${i.id}, Name: ${i.name}, Category: ${i.category}, Brand: ${i.brand ?? "Unknown"}',
        )
        .join('\n');

    final wishlistContext = wishlist
        .map(
          (i) =>
              'ID: ${i.id}, Name: ${i.productName}, Brand: ${i.brand ?? "Unknown"}',
        )
        .join('\n');

    final prompt =
        '''
You are a high-end personal stylist for "The Atelier", a luxury digital wardrobe app. 
Your goal is to curate a cohesive, aesthetic outfit using items from the user's wardrobe and potentially one item from their wishlist.

USER CONTEXT:
${mood != null ? "Current Mood/Occasion: $mood" : ""}

WARDROBE ITEMS:
$wardrobeContext

WISHLIST ITEMS (Target for purchase):
$wishlistContext

INSTRUCTIONS:
1. Select 2-4 items from the WARDROBE that form a stylish outfit.
2. (Optional) You may include ONE item from the WISHLIST if it perfectly complements the wardrobe pieces.
3. Provide a creative, editorial name for the outfit.
4. Provide a brief (1 sentence) justification for the styling choice.

OUTPUT FORMAT (JSON ONLY):
{
  "name": "Editorial Outfit Name",
  "wardrobe_item_ids": ["id1", "id2"],
  "wishlist_item_ids": ["optional_id"],
  "justification": "Why this works..."
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) return null;

      final data = jsonDecode(response.text!);
      return AISuggestion.fromJson(data);
    } catch (e) {
      print('AI Service Error: \$e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> suggestPackingList({
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    String? weatherDescription,
    String? purpose,
    required List<WardrobeItem> wardrobe,
  }) async {
    final days = endDate.difference(startDate).inDays;
    
    if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      // Mock fallback for UI testing if no key is provided
      await Future.delayed(const Duration(seconds: 2));
      return [
        {'id': 'w1', 'name': 'Linen Button-down', 'category': 'TOPS', 'isAIRecommended': true},
        {'id': 'w2', 'name': 'Chino Shorts', 'category': 'BOTTOMS', 'isAIRecommended': true},
        {'id': 'w3', 'name': 'Sunglasses', 'category': 'ACCESSORIES', 'isAIRecommended': true},
        {'id': 'w4', 'name': 'Swim Trunks', 'category': 'SWIMWEAR', 'isAIRecommended': true},
      ];
    }

    final wardrobeContext = wardrobe
        .map((i) => 'ID: \${i.id}, Name: \${i.name}, Category: \${i.category}')
        .join('\\n');

    final prompt = '''
You are a luxury travel concierge and personal stylist for "The Atelier", a high-end digital wardrobe app.
Your client is traveling to $destination.
The trip lasts $days days.
Weather description: ${weatherDescription ?? "Unknown"}
Trip Purpose: ${purpose ?? "Leisure"}

Here is their current wardrobe:
$wardrobeContext

INSTRUCTIONS:
1. Generate a curated packing list tailored to the destination, weather, and duration.
2. YOU MUST STRICTLY ONLY SELECT ITEMS EXPLICITLY LISTED IN THE WARDROBE CONTEXT ABOVE.
3. DO NOT invent or suggest any clothing, shoes, or accessories that are not in the provided list.
4. Organize items by category (e.g. TOPS, BOTTOMS, DRESSES, OUTERWEAR, SHOES, ACCESSORIES). If the wardrobe has no items for a category, omit the category.
5. Output MUST be ONLY valid JSON matching this exact structure:

[
  {"id": "WARDROBE_ITEM_ID", "name": "Item Name", "category": "CATEGORY"}
]


Make the names sound elegant but practical. Return ONLY the JSON array, no markdown blocks.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) return null;

      // Clean up potential markdown formatting from Gemini response
      var jsonText = response.text!.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }

      final List<dynamic> data = jsonDecode(jsonText.trim());
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('AI Packing Service Error: \$e');
      return null;
    }
  }
}
