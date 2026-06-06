import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/models/approval_subordinate_model.dart';
import 'package:mobile_app/providers/approval_provider.dart';
import 'package:mobile_app/widgets/absence_card.dart';
import 'package:mobile_app/widgets/loading_indicator.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovalProvider>().loadPendingApprovals();
    });
  }

  Future<void> _showDecisionDialog(
    BuildContext context,
    AbsenceRequestModel request,
    bool approve,
  ) async {
    final provider = context.read<ApprovalProvider>();
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(approve ? 'Genehmigen' : 'Ablehnen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Möchten Sie den Antrag wirklich ${approve ? 'genehmigen' : 'ablehnen'}?'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Begründung (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (approve) {
      await provider.approve(requestId: request.id, comment: controller.text.trim());
    } else {
      await provider.reject(requestId: request.id, comment: controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Genehmigungen Team'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Offen'),
              Tab(text: 'Genehmigt'),
              Tab(text: 'Soldaten'),
            ],
          ),
        ),
        body: Consumer<ApprovalProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingIndicator(message: 'Lade Team-Anträge...');
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(provider.errorMessage!),
                ),
              );
            }

            return TabBarView(
              children: [
                _ApprovalsList(
                  requests: provider.pendingApprovals,
                  emptyText: 'Keine offenen Anträge im Team.',
                  trailingBuilder: (request) => Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _showDecisionDialog(context, request, false),
                        child: const Text('Ablehnen'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showDecisionDialog(context, request, true),
                        child: const Text('Genehmigen'),
                      ),
                    ],
                  ),
                ),
                _ApprovalsList(
                  requests: provider.approvedApprovals,
                  emptyText: 'Keine genehmigten Anträge im Team.',
                ),
                _SubordinatesList(subordinates: provider.subordinates),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ApprovalsList extends StatelessWidget {
  final List<AbsenceRequestModel> requests;
  final String emptyText;
  final Widget Function(AbsenceRequestModel request)? trailingBuilder;

  const _ApprovalsList({
    required this.requests,
    required this.emptyText,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ApprovalProvider>().loadPendingApprovals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final requestedBy = request.requestedByName == null
              ? null
              : '${request.requestedByName} (${request.requestedByPersonalNumber ?? '-'})';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (requestedBy != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Antrag von: $requestedBy',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              AbsenceCard(absence: request),
              if (trailingBuilder != null) trailingBuilder!(request),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _SubordinatesList extends StatelessWidget {
  final List<ApprovalSubordinateModel> subordinates;

  const _SubordinatesList({required this.subordinates});

  @override
  Widget build(BuildContext context) {
    if (subordinates.isEmpty) {
      return const Center(child: Text('Keine unterstellten Soldaten gefunden.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: subordinates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final subordinate = subordinates[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(subordinate.displayName),
            subtitle: Text('${subordinate.rank} · ${subordinate.personalNumber}\n${subordinate.unit}\n${subordinate.email} · ${subordinate.phoneNumber}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _SubordinateDetailScreen(subordinate: subordinate),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SubordinateDetailScreen extends StatefulWidget {
  final ApprovalSubordinateModel subordinate;

  const _SubordinateDetailScreen({required this.subordinate});

  @override
  State<_SubordinateDetailScreen> createState() => _SubordinateDetailScreenState();
}

class _SubordinateDetailScreenState extends State<_SubordinateDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AbsenceRequestModel> _requests = [];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  List<AbsenceRequestModel> _eventsForDay(DateTime day) {
    final date = _dateOnly(day);
    return _requests.where((absence) {
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<ApprovalProvider>();
      final requests = await provider.loadSubordinateRequests(widget.subordinate.id);
      setState(() {
        _requests = requests;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final selectedDayAbsences = _eventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subordinate.displayName),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Lade Soldatenübersicht...')
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_errorMessage!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.subordinate.rank} · ${widget.subordinate.personalNumber}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(widget.subordinate.unit),
                              const SizedBox(height: 2),
                              Text(widget.subordinate.email),
                              const SizedBox(height: 2),
                              Text(widget.subordinate.phoneNumber),
                              const SizedBox(height: 10),
                              TableCalendar<AbsenceRequestModel>(
                                firstDay: DateTime(DateTime.now().year - 1, 1, 1),
                                lastDay: DateTime(DateTime.now().year + 1, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                                eventLoader: _eventsForDay,
                                headerStyle: const HeaderStyle(
                                  titleCentered: true,
                                  formatButtonVisible: false,
                                ),
                                calendarStyle: const CalendarStyle(
                                  outsideDaysVisible: false,
                                ),
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, date, events) {
                                    if (events.isEmpty) return const SizedBox.shrink();
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 14,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: _statusColor(events.first.status),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                              left: BorderSide(color: _statusColor(absence.status), width: 5),
                            ),
                          ),
                          child: Text(
                            '${absence.type.name}: ${dateFormat.format(absence.startDate)} - ${dateFormat.format(absence.endDate)} · ${_statusLabel(absence.status)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Alle Anträge',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ..._requests.map((absence) => AbsenceCard(absence: absence)),
                    ],
                  ),
                ),
    );
  }
}
