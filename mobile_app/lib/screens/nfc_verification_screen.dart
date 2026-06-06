import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/core/routes.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/nfc_service.dart';
import 'package:mobile_app/widgets/app_text_field.dart';
import 'package:mobile_app/widgets/bundeswehr_camouflage_background.dart';
import 'package:mobile_app/widgets/error_message_box.dart';
import 'package:mobile_app/widgets/primary_button.dart';

class NfcVerificationScreen extends StatefulWidget {
  const NfcVerificationScreen({super.key});

  @override
  State<NfcVerificationScreen> createState() => _NfcVerificationScreenState();
}

class _NfcVerificationScreenState extends State<NfcVerificationScreen> {
  final _manualTokenController = TextEditingController();
  bool _isScanning = false;
  bool _obscureTokenInput = true;

  @override
  void dispose() {
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify(AuthProvider authProvider, {String? manualToken}) async {
    final success = await authProvider.verifyNfc(manualToken: manualToken);
    if (!success) return;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.dashboard);
  }

  Future<void> _scanTokenIntoInput() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final scanner = context.read<NfcService>();
      final token = await scanner.scanToken();

      if (!mounted) return;

      if (token == null || token.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein NFC-Token erkannt.')),
        );
        return;
      }

      _manualTokenController.text = token.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token gelesen.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC-Scan fehlgeschlagen.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _verifyFromInput(AuthProvider auth) async {
    final value = _manualTokenController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst Token scannen oder eingeben.')),
      );
      return;
    }

    await _handleVerify(auth, manualToken: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC-Verifikation')),
      body: BundeswehrCamouflageBackground(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Bitte halten Sie Ihr NFC-Token an das Gerät oder geben Sie im Testmodus einen Token ein.',
                  ),
                  const SizedBox(height: 16),
                  if (auth.errorMessage != null)
                    ErrorMessageBox(message: auth.errorMessage!),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.nfc),
                    label: const Text('NFC scannen'),
                    onPressed: auth.isLoading || _isScanning
                        ? null
                        : _scanTokenIntoInput,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: kDebugMode ? 'Token (Scan oder Debug)' : 'Token',
                    controller: _manualTokenController,
                    hint: 'z. B. NFC-100000',
                    obscureText: _obscureTokenInput,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _obscureTokenInput = !_obscureTokenInput;
                        });
                      },
                      icon: Icon(
                        _obscureTokenInput ? Icons.visibility : Icons.visibility_off,
                      ),
                      label: Text(
                        _obscureTokenInput ? 'Token anzeigen' : 'Token verbergen',
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Token prüfen',
                    isLoading: auth.isLoading,
                    onPressed: () => _verifyFromInput(auth),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            auth.logout();
                            Navigator.of(context).pushReplacementNamed(Routes.login);
                          },
                    child: const Text('Abbrechen / Zurück'),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
