import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/screens/admin_home_screen.dart';
import 'package:mobile_app/core/bundeswehr_theme.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_app/core/routes.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/providers/absence_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/widgets/bundeswehr_camouflage_background.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  List<AbsenceRequestModel> _eventsForDay(
    List<AbsenceRequestModel> absences,
    DateTime day,
  ) {
    final date = _dateOnly(day);
    return absences.where((absence) {
      final start = _dateOnly(absence.startDate);
      final end = _dateOnly(absence.endDate);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  Color _statusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.approved:
        return const Color(0xFF2E7D32);
      case AbsenceStatus.rejected:
        return const Color(0xFFC62828);
      case AbsenceStatus.cancelled:
        return const Color(0xFF6D6D6D);
      case AbsenceStatus.pending:
        return const Color(0xFFEF6C00);
    }
  }

  String _statusLabel(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.approved:
        return 'Genehmigt';
      case AbsenceStatus.rejected:
        return 'Abgelehnt';
      case AbsenceStatus.cancelled:
        return 'Storniert';
      case AbsenceStatus.pending:
        return 'Offen';
    }
  }

  List<Color> _statusColorsForEvents(List<AbsenceRequestModel> events) {
    final colors = <Color>[];

    for (final event in events) {
      final color = _statusColor(event.status);
      if (!colors.contains(color)) {
        colors.add(color);
      }
    }

    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 108,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(Routes.profile),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.person_outline),
            label: const Text('Profil'),
          ),
        ),
        title: Row(
          children: const [
            Icon(Icons.shield, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dienstübersicht',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              auth.logout();
              Navigator.of(context).pushReplacementNamed(Routes.login);
            },
          ),
        ],
      ),
      body: BundeswehrCamouflageBackground(
        child: Consumer2<AuthProvider, AbsenceProvider>(
          builder: (context, auth, absenceProvider, child) {
            final user = auth.user;
            final absences = absenceProvider.myAbsences;
            final selectedDayAbsences = _eventsForDay(absences, _selectedDay);
            final adminMode = auth.isAdmin;
            final hasCalendarPage = auth.isSoldier && !adminMode;

            final pages = <Widget>[];

            pages.add(
              _buildOverviewPage(
                auth: auth,
                absenceProvider: absenceProvider,
                user: user,
              ),
            );

            if (adminMode) {
              pages.add(const AdminHomeContent());
            }

            if (hasCalendarPage) {
              pages.add(
                _buildCalendarPage(
                  auth: auth,
                  absences: absences,
                  selectedDayAbsences: selectedDayAbsences,
                  dateFormat: dateFormat,
                ),
              );
            }

            if (!adminMode) {
              pages.add(_buildActionsPage(auth));
            }

            final maxIndex = pages.length - 1;
            if (_currentPage > maxIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _currentPage = maxIndex;
                });
                _pageController.jumpToPage(maxIndex);
              });
            }

            return PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: pages,
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final hasCalendarPage = auth.isSoldier;
            final adminMode = auth.isAdmin;
            final pageDots = <({int index, String tooltip})>[];

            if (adminMode) {
              pageDots.add((index: 0, tooltip: 'Übersicht'));
              pageDots.add((index: 1, tooltip: 'Admin'));
            } else {
              pageDots.add((index: 0, tooltip: 'Übersicht'));
              if (hasCalendarPage) {
                pageDots.add((index: 1, tooltip: 'Kalender'));
                pageDots.add((index: 2, tooltip: 'Menü'));
              } else {
                pageDots.add((index: 1, tooltip: 'Menü'));
              }
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              color: BundeswehrTheme.olive900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pageDots.length; i++) ...[
                    _PageDot(
                      isSelected: _currentPage == pageDots[i].index,
                      onTap: () => _goToPage(pageDots[i].index),
                      tooltip: pageDots[i].tooltip,
                    ),
                    if (i != pageDots.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Widget _buildOverviewPage({
    required AuthProvider auth,
    required AbsenceProvider absenceProvider,
    required dynamic user,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        if (auth.isSoldier) {
          await absenceProvider.loadMyAbsences();
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: BundeswehrTheme.olive900,
                        ),
                        child: const Center(
                          child: Text(
                            'BW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user == null
                              ? 'Willkommen'
                              : 'Willkommen, ${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user == null
                        ? ''
                        : '${user.rank.isEmpty ? 'Dienstgrad offen' : user.rank} · ${user.unit.isEmpty ? 'Einheit offen' : user.unit}',
                    style: const TextStyle(color: Color(0xFF4B4B4B)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BundeswehrTheme.olive700.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Rollen: ${auth.roles.join(', ')}'),
                  ),
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
                      'Urlaubstage (nur Werktage Mo-Fr)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _YearVacationPanel(
                      year: absenceProvider.currentYear,
                      remainingDays: absenceProvider
                          .remainingVacationDaysForYear(
                            absenceProvider.currentYear,
                          ),
                      bookedDays: absenceProvider.bookedVacationDaysForYear(
                        absenceProvider.currentYear,
                      ),
                      approvedDays: absenceProvider.approvedVacationDaysForYear(
                        absenceProvider.currentYear,
                      ),
                      openRequests: absenceProvider.openAbsenceRequestsCount,
                    ),
                    const SizedBox(height: 12),
                    _YearVacationPanel(
                      year: absenceProvider.previousYear,
                      remainingDays: absenceProvider
                          .remainingVacationDaysForYear(
                            absenceProvider.previousYear,
                          ),
                      bookedDays: absenceProvider.bookedVacationDaysForYear(
                        absenceProvider.previousYear,
                      ),
                      approvedDays: absenceProvider.approvedVacationDaysForYear(
                        absenceProvider.previousYear,
                      ),
                      openRequests: 0,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            auth.isAdmin
                ? 'Wische nach links/rechts oder nutze die Punkte unten, um zwischen Übersicht und Admin-Bereich zu wechseln.'
                : auth.isSoldier
                ? 'Wische nach links/rechts oder nutze die Punkte unten, um zwischen Übersicht, Kalender und Menü zu wechseln.'
                : 'Wische nach links/rechts oder nutze die Punkte unten, um zwischen Übersicht und Menü zu wechseln.',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPage({
    required AuthProvider auth,
    required List<AbsenceRequestModel> absences,
    required List<AbsenceRequestModel> selectedDayAbsences,
    required DateFormat dateFormat,
  }) {
    if (!auth.isSoldier) {
      return const Center(
        child: Text('Kalender ist nur für Soldaten sichtbar.'),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Kalender',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                TableCalendar<AbsenceRequestModel>(
                  firstDay: DateTime(DateTime.now().year - 1, 1, 1),
                  lastDay: DateTime(DateTime.now().year + 1, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  eventLoader: (day) => _eventsForDay(absences, day),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: const BoxDecoration(
                      color: Color(0xFF2E3A1F),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF0D47A1),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                  ),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();

                      final colors = _statusColorsForEvents(events);

                      if (colors.length == 1) {
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 18,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.first,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }

                      final limited = colors.take(3).toList();
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: limited
                              .map(
                                (color) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  width: 6,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: const [
                    _LegendDot(label: 'Offen', color: Color(0xFFEF6C00)),
                    _LegendDot(label: 'Genehmigt', color: Color(0xFF2E7D32)),
                    _LegendDot(label: 'Abgelehnt', color: Color(0xFFC62828)),
                    _LegendDot(label: 'Storniert', color: Color(0xFF6D6D6D)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anträge am ${dateFormat.format(_selectedDay)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (selectedDayAbsences.isEmpty)
                  const Text('Keine Einträge am gewählten Tag.'),
                ...selectedDayAbsences.map(
                  (absence) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.8),
                      border: Border(
                        left: BorderSide(
                          color: _statusColor(absence.status),
                          width: 5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          absence.type.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(absence.startDate)} - ${dateFormat.format(absence.endDate)} · ${_statusLabel(absence.status)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsPage(AuthProvider auth) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Schnellzugriff',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (auth.isSoldier)
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.myAbsences),
                    icon: const Icon(Icons.event_note),
                    label: const Text('Meine Abwesenheiten'),
                  ),
                if (auth.isSoldier)
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.createAbsence),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Neuer Antrag'),
                  ),
                if (auth.isApprover && !auth.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(Routes.pendingApprovals),
                    icon: const Icon(Icons.assignment_turned_in),
                    label: const Text('Genehmigungen'),
                  ),
                if (auth.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.adminCreateUser),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Nutzer erstellen'),
                  ),
                if (auth.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(Routes.adminManageUsers),
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Nutzerverwaltung'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}

class _YearVacationPanel extends StatelessWidget {
  final int year;
  final int remainingDays;
  final int bookedDays;
  final int approvedDays;
  final int openRequests;

  const _YearVacationPanel({
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
              child: _InfoBox(
                title: 'Offene Urlaubstage',
                value: remainingDays.toString(),
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoBox(
                title: 'Geplante Urlaubstage',
                value: bookedDays.toString(),
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoBox(
                title: 'Bereits genehmigt',
                value: approvedDays.toString(),
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoBox(
                title: 'Offene Anträge',
                value: openRequests.toString(),
                color: const Color(0xFFEF6C00),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _PageDot({
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 18 : 11,
          height: 11,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: isSelected
                ? const Color(0xFF9C8A3F)
                : Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
