import 'package:flutter/material.dart';
import 'wardrobe_screen.dart';
import 'wishlist_screen.dart';
import 'outfit_designer_screen.dart';
import 'travel_planner_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const WardrobeScreen(),
    const WishlistScreen(),
    const OutfitDesignerScreen(),
    const TravelPlannerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'THE ATELIER',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // The current screen
          _screens[_currentIndex],
          
          // Floating Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavBarItem(
                      icon: Icons.checkroom_outlined,
                      activeIcon: Icons.checkroom,
                      label: 'WARDROBE',
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                      theme: theme,
                      cs: cs,
                    ),
                    _NavBarItem(
                      icon: Icons.favorite_border,
                      activeIcon: Icons.favorite,
                      label: 'WISHLIST',
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                      theme: theme,
                      cs: cs,
                    ),
                    _NavBarItem(
                      icon: Icons.style_outlined,
                      activeIcon: Icons.style,
                      label: 'DESIGNER',
                      isSelected: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
                      theme: theme,
                      cs: cs,
                    ),
                    _NavBarItem(
                      icon: Icons.card_travel_outlined,
                      activeIcon: Icons.card_travel,
                      label: 'TRIPS',
                      isSelected: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                      theme: theme,
                      cs: cs,
                    ),
                    _NavBarItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'PROFILE',
                      isSelected: _currentIndex == 4,
                      onTap: () => setState(() => _currentIndex = 4),
                      theme: theme,
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme cs;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
            size: 20, // Reduced slightly for 5 items
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 7, // Reduced for 5 items
              letterSpacing: 1.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
