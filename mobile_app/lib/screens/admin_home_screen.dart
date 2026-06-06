import 'package:flutter/material.dart';
import 'package:mobile_app/core/bundeswehr_theme.dart';
import 'package:mobile_app/core/routes.dart';
import 'package:mobile_app/widgets/bundeswehr_camouflage_background.dart';
import 'package:mobile_app/widgets/bundeswehr_logo.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: const AdminHomeContent(),
    );
  }
}

class AdminHomeContent extends StatelessWidget {
  const AdminHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BundeswehrCamouflageBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BundeswehrLogo(size: 92, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'Admin-Bereich',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wähle den gewünschten Verwaltungsbereich.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;

                    final children = [
                      _AdminActionCard(
                        title: 'Nutzer erstellen',
                        description:
                            'Neue Accounts inklusive Rolle, Einheit und Initialpasswort anlegen.',
                        icon: Icons.person_add_alt_1,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(Routes.adminCreateUser),
                      ),
                      _AdminActionCard(
                        title: 'Nutzerverwaltung',
                        description:
                            'Nutzer bearbeiten, sperren, löschen, Passwort zurücksetzen und NFC verwalten.',
                        icon: Icons.manage_accounts,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(Routes.adminManageUsers),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: [
                          children[0],
                          const SizedBox(height: 12),
                          children[1],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 12),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BundeswehrTheme.olive700.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: BundeswehrTheme.olive900),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(description),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Öffnen', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
