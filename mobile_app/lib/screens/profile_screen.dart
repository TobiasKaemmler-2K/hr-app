import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/absence_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isSoldier) return;

      final absenceProvider = context.read<AbsenceProvider>();
      if (absenceProvider.myAbsences.isEmpty && !absenceProvider.isLoading) {
        absenceProvider.loadMyAbsences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD5D0BE), Color(0xFFE9E4D6)],
          ),
        ),
        child: Consumer2<AuthProvider, AbsenceProvider>(
          builder: (context, auth, absenceProvider, child) {
            final user = auth.user;
            if (user == null) {
              return const Center(child: Text('Keine Profildaten geladen.'));
            }

            final infoTiles = <Widget>[
              _InfoTile(label: 'Name', value: '${user.firstName} ${user.lastName}'),
              _InfoTile(label: 'Personalnummer', value: user.personalNumber),
              _InfoTile(label: 'E-Mail', value: user.email.isEmpty ? 'Nicht hinterlegt' : user.email),
              _InfoTile(label: 'Telefon', value: user.phoneNumber.isEmpty ? 'Nicht hinterlegt' : user.phoneNumber),
              _InfoTile(label: 'Dienstgrad', value: user.rank.isEmpty ? 'Nicht hinterlegt' : user.rank),
              _InfoTile(label: 'Einheit', value: user.unit.isEmpty ? 'Nicht hinterlegt' : user.unit),
              _InfoTile(label: 'Rolle', value: auth.roles.join(', ')),
            ];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(
                              backgroundColor: Color(0xFF2E3A1F),
                              foregroundColor: Colors.white,
                              child: Icon(Icons.shield),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Soldatenprofil',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...infoTiles,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (auth.isSoldier)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Urlaubsübersicht (nur Werktage Mo-Fr)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _YearStats(
                            year: absenceProvider.currentYear,
                            remainingDays: absenceProvider.remainingVacationDaysForYear(absenceProvider.currentYear),
                            bookedDays: absenceProvider.bookedVacationDaysForYear(absenceProvider.currentYear),
                            approvedDays: absenceProvider.approvedVacationDaysForYear(absenceProvider.currentYear),
                            openRequests: absenceProvider.openAbsenceRequestsCount,
                          ),
                          const SizedBox(height: 12),
                          _YearStats(
                            year: absenceProvider.previousYear,
                            remainingDays: absenceProvider.remainingVacationDaysForYear(absenceProvider.previousYear),
                            bookedDays: absenceProvider.bookedVacationDaysForYear(absenceProvider.previousYear),
                            approvedDays: absenceProvider.approvedVacationDaysForYear(absenceProvider.previousYear),
                            openRequests: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Passwort ändern',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Aktuelles Passwort',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Neues Passwort',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Neues Passwort bestätigen',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (auth.errorMessage != null) ...[
                          Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ElevatedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  final currentPassword = _currentPasswordController.text.trim();
                                  final newPassword = _newPasswordController.text.trim();
                                  final confirmPassword = _confirmPasswordController.text.trim();

                                  if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bitte alle Passwortfelder ausfüllen.')),
                                    );
                                    return;
                                  }

                                  if (newPassword != confirmPassword) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Neues Passwort und Bestätigung stimmen nicht überein.')),
                                    );
                                    return;
                                  }

                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await auth.changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword,
                                  );

                                  if (!mounted) return;
                                  if (ok) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Passwort erfolgreich geändert.')),
                                    );
                                  }
                                },
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Passwort ändern'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label),
        ],
      ),
    );
  }
}

class _YearStats extends StatelessWidget {
  final int year;
  final int remainingDays;
  final int bookedDays;
  final int approvedDays;
  final int openRequests;

  const _YearStats({
    required this.year,
    required this.remainingDays,
    required this.bookedDays,
    required this.approvedDays,
    required this.openRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jahr $year (Kontingent: 30 Tage)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricChip(
                label: 'Offene Urlaubstage',
                value: remainingDays.toString(),
                color: const Color(0xFF3D6B35),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricChip(
                label: 'Geplante Urlaubstage',
                value: bookedDays.toString(),
                color: const Color(0xFF2D5E8B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricChip(
                label: 'Bereits genehmigt',
                value: approvedDays.toString(),
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricChip(
                label: 'Offene Anträge',
                value: openRequests.toString(),
                color: const Color(0xFF8B5A2B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}