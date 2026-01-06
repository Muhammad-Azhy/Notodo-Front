import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import "../screens/view_profile_page.dart";

class AppHeader extends StatelessWidget {
  final String username;

  const AppHeader({super.key, required this.username});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${_greeting()}",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
              onSelected: (value) {
                if (value == "theme") {
                  context.read<ThemeProvider>().toggleTheme();
                } else if (value == "profile") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewProfilePage()),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: "profile", child: Text("Profile")),
                PopupMenuItem(value: "theme", child: Text("Change Theme")),
                PopupMenuItem(value: "about", child: Text("About")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
