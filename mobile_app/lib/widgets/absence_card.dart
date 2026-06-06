import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/widgets/status_badge.dart';

class AbsenceCard extends StatelessWidget {
  final AbsenceRequestModel absence;
  final VoidCallback? onCancel;

  const AbsenceCard({
    super.key,
    required this.absence,
    this.onCancel,
  });

  Color _statusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
      case AbsenceStatus.cancelled:
        return Colors.grey;
      case AbsenceStatus.pending:
        return Colors.orange;
    }
  }

  String _statusLabel(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.approved:
        return 'Genehmigt';
      case AbsenceStatus.rejected:
        return 'Abgelehnt';
      case AbsenceStatus.cancelled:
        return 'Zurückgezogen';
      case AbsenceStatus.pending:
        return 'Offen';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final range = '${dateFormat.format(absence.startDate)} – ${dateFormat.format(absence.endDate)}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  absence.type.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                StatusBadge(
                  label: _statusLabel(absence.status),
                  color: _statusColor(absence.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(range),
            if (absence.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                absence.reason,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            if (onCancel != null && absence.status == AbsenceStatus.pending) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('Zurückziehen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
