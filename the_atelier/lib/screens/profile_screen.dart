import 'package:flutter/material.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        _buildHeader(theme, cs),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('ACCOUNT', theme, cs),
                _buildProfileTile(Icons.person_outline, 'Edit Profile', theme, cs),
                _buildProfileTile(Icons.notifications_none, 'Notifications', theme, cs),
                _buildProfileTile(Icons.lock_outline, 'Privacy & Security', theme, cs),
                
                const SizedBox(height: 32),
                _buildSectionTitle('PREMIUM', theme, cs),
                _buildPremiumCard(context, theme),
                
                const SizedBox(height: 32),
                _buildSectionTitle('SUPPORT', theme, cs),
                _buildProfileTile(Icons.help_outline, 'Help Center', theme, cs),
                _buildProfileTile(Icons.info_outline, 'About The Atelier', theme, cs),
                
                const SizedBox(height: 48),
                _buildLogoutButton(theme, cs),
                const SizedBox(height: 120), // Space for floating nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1974&auto=format&fit=crop'),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elena Rossi',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Style Enthusiast • Milan, Italy',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: cs.onSurface.withOpacity(0.8)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 2,
          color: cs.onSurface.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.onSurface.withOpacity(0.7), size: 20),
        title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3), size: 20),
        onTap: () {},
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF5D634F), const Color(0xFF5D634F).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D634F).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'THE ATELIER PREMIER',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock AI Journey Planner, unlimited outfits, and priority styling tips.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5D634F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, ColorScheme cs) {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Log Out',
          style: TextStyle(
            color: cs.error,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
