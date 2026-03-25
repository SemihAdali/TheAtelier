import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'models/outfit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  
  // Load persisted outfits into the global cache
  mockOutfits = StorageService.instance.getOutfits();

  await Supabase.initialize(
    url: 'https://smvlqyycshkgmrmxtxyj.supabase.co',
    anonKey: 'sb_publishable_LIPIM2i9QxrcLwoVXgu1hg_SAUWWXDf',
  );

  runApp(const TheAtelierApp());
}

class TheAtelierApp extends StatelessWidget {
  const TheAtelierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Atelier',
      theme: AppTheme.lightTheme,
      home: const AtelierHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AtelierHome extends StatelessWidget {
  const AtelierHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Let the content breathe with generous padding
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asymmetrical, editorial header
              Text(
                'The\nDigital\nAtelier.',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Your curated wardrobe, beautifully organized.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              
              // Primary CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                    );
                  },
                  child: const Text('Enter the Atelier'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

