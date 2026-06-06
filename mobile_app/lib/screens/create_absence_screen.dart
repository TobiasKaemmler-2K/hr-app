import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/absence_type_model.dart';
import 'package:mobile_app/providers/absence_provider.dart';
import 'package:mobile_app/widgets/app_text_field.dart';
import 'package:mobile_app/widgets/error_message_box.dart';
import 'package:mobile_app/widgets/primary_button.dart';

class CreateAbsenceScreen extends StatefulWidget {
  const CreateAbsenceScreen({super.key});

  @override
  State<CreateAbsenceScreen> createState() => _CreateAbsenceScreenState();
}

class _CreateAbsenceScreenState extends State<CreateAbsenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTimeRange? _selectedRange;
  AbsenceTypeModel? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbsenceProvider>().loadAbsenceTypes();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 2);

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: firstDate,
      lastDate: lastDate,
      saveText: 'Übernehmen',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedRange = picked;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRange == null) return;
    if (_selectedType == null) return;

    final provider = context.read<AbsenceProvider>();

    final success = await provider.createAbsence(
      typeId: _selectedType!.id,
      startDate: _selectedRange!.start,
      endDate: _selectedRange!.end,
      reason: _reasonController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Neuen Antrag erstellen')),
      body: Consumer<AbsenceProvider>(
        builder: (context, provider, child) {
          final types = provider.absenceTypes;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<AbsenceTypeModel>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Abwesenheitsart',
                            border: OutlineInputBorder(),
                          ),
                          items: types
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _selectedType = value),
                          validator: (value) {
                            if (types.isEmpty) {
                              return 'Keine Abwesenheitsarten vom Server verfügbar';
                            }
                            if (value == null) {
                              return 'Bitte eintragen';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Zeitraum',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            hintText: _selectedRange != null
                                ? '${dateFormatter.format(_selectedRange!.start)} - ${dateFormatter.format(_selectedRange!.end)}'
                              : 'Start und Ende wählen',
                          ),
                          onTap: _pickDateRange,
                          validator: (value) {
                            if (_selectedRange == null) {
                              return 'Bitte Zeitraum wählen';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Begründung',
                          controller: _reasonController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte Begründung eingeben';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (provider.errorMessage != null)
                          ErrorMessageBox(message: provider.errorMessage!),
                        PrimaryButton(
                          label: 'Antrag stellen',
                          isLoading: provider.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
