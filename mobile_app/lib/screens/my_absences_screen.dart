import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/providers/absence_provider.dart';
import 'package:mobile_app/widgets/absence_card.dart';
import 'package:mobile_app/widgets/loading_indicator.dart';

class MyAbsencesScreen extends StatefulWidget {
  const MyAbsencesScreen({super.key});

  @override
  State<MyAbsencesScreen> createState() => _MyAbsencesScreenState();
}

class _MyAbsencesScreenState extends State<MyAbsencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbsenceProvider>().loadMyAbsences();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meine Abwesenheiten')),
      body: Consumer<AbsenceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(message: 'Lade Anträge...');
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.myAbsences.isEmpty) {
            return const Center(child: Text('Keine Abwesenheitsanträge vorhanden.'));
          }

          return RefreshIndicator(
            onRefresh: provider.loadMyAbsences,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myAbsences.length,
              itemBuilder: (context, index) {
                final absence = provider.myAbsences[index];
                return AbsenceCard(
                  absence: absence,
                  onCancel: absence.status == AbsenceStatus.pending
                      ? () => provider.cancelAbsence(absence.id)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
