import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/core/routes.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/widgets/bundeswehr_camouflage_background.dart';
import 'package:mobile_app/widgets/app_text_field.dart';
import 'package:mobile_app/widgets/error_message_box.dart';
import 'package:mobile_app/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personalNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.loadFromStorage();
      if (auth.isAuthenticated) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    });
  }

  @override
  void dispose() {
    _personalNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final response = await authProvider.login(
      personalNumber: _personalNumberController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (response == null) return;

    if (response.requiresNfc) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.nfcVerification);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BundeswehrCamouflageBackground(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AppTextField(
                            label: 'Personalnummer',
                            controller: _personalNumberController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bitte Personalnummer eingeben';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Passwort',
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bitte Passwort eingeben';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          if (auth.errorMessage != null)
                            ErrorMessageBox(message: auth.errorMessage!),
                          PrimaryButton(
                            label: 'Anmelden',
                            isLoading: auth.isLoading,
                            onPressed: () => _onLoginPressed(auth),
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
      ),
    );
  }
}
