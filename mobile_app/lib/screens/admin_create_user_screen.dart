import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/admin_provider.dart';
import 'package:mobile_app/widgets/app_text_field.dart';
import 'package:mobile_app/widgets/error_message_box.dart';
import 'package:mobile_app/widgets/primary_button.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _personalNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _unitController = TextEditingController();
  final _rankController = TextEditingController();
  final _initialPasswordController = TextEditingController();
  final _rolesController = TextEditingController(text: 'SOLDAT');

  @override
  void dispose() {
    _personalNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _unitController.dispose();
    _rankController.dispose();
    _initialPasswordController.dispose();
    _rolesController.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _createUser(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final created = await admin.createUser(
      personalNumber: _personalNumberController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      unit: _unitController.text.trim(),
      rank: _rankController.text.trim(),
      initialPassword: _initialPasswordController.text.trim(),
      roles: _parseCsv(_rolesController.text),
    );

    if (!created) {
      return;
    }

    _personalNumberController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _unitController.clear();
    _rankController.clear();
    _initialPasswordController.clear();
    _rolesController.text = 'SOLDAT';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutzer erstellen')),
      body: Consumer<AdminProvider>(
        builder: (context, admin, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (admin.errorMessage != null)
                ErrorMessageBox(message: admin.errorMessage!),
              if (admin.successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.30),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(admin.successMessage!),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Personalnummer',
                          controller: _personalNumberController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Pflichtfeld'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Vorname',
                          controller: _firstNameController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Pflichtfeld'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Nachname',
                          controller: _lastNameController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Pflichtfeld'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'E-Mail',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Ungültige E-Mail'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Telefon',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Pflichtfeld'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Einheit',
                          controller: _unitController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Pflichtfeld'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Dienstgrad',
                          controller: _rankController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Pflichtfeld'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Initiales Passwort',
                          controller: _initialPasswordController,
                          obscureText: true,
                          validator: (v) => v == null || v.trim().length < 6
                              ? 'Mindestens 6 Zeichen'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          label: 'Rollen (CSV)',
                          hint: 'SOLDAT,VORGESETZTER,ADMIN',
                          controller: _rolesController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Mindestens eine Rolle'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Nutzer anlegen',
                          isLoading: admin.isSubmitting,
                          onPressed: () => _createUser(admin),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
