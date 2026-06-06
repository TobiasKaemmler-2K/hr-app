import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/admin_nfc_token_model.dart';
import 'package:mobile_app/models/admin_user_model.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/admin_provider.dart';
import 'package:mobile_app/widgets/app_text_field.dart';
import 'package:mobile_app/widgets/error_message_box.dart';
import 'package:mobile_app/widgets/loading_indicator.dart';
import 'package:mobile_app/widgets/primary_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  static const String _protectedBootstrapAdminPersonalNumber = '100000';
  late final TabController _tabController;

  final _issueTokenFormKey = GlobalKey<FormState>();

  final _issueTokenIdentifierController = TextEditingController();
  bool _revokeCurrentActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _issueTokenIdentifierController.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _showResetPasswordDialog(
    BuildContext context,
    AdminUserModel user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Passwort zurücksetzen: ${user.displayName}'),
          content: Form(
            key: formKey,
            child: AppTextField(
              label: 'Neues Passwort',
              controller: passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'Mindestens 6 Zeichen';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Zurücksetzen'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) {
        passwordController.dispose();
        return;
      }

      await this.context.read<AdminProvider>().resetPassword(
        userId: user.id,
        newPassword: passwordController.text.trim(),
      );
    }

    passwordController.dispose();
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    AdminUserModel user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final personalNumberController = TextEditingController(
      text: user.personalNumber,
    );
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final unitController = TextEditingController(text: user.unit);
    final rankController = TextEditingController(text: user.rank);
    final rolesController = TextEditingController(text: user.roles.join(','));

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Nutzer bearbeiten: ${user.displayName}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Personalnummer',
                      controller: personalNumberController,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Vorname',
                      controller: firstNameController,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Nachname',
                      controller: lastNameController,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'E-Mail',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Ungültige E-Mail'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Telefon',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Einheit',
                      controller: unitController,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Dienstgrad',
                      controller: rankController,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Rollen (CSV)',
                      hint: 'SOLDAT,VORGESETZTER,ADMIN',
                      controller: rolesController,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Mindestens eine Rolle'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) {
        personalNumberController.dispose();
        firstNameController.dispose();
        lastNameController.dispose();
        emailController.dispose();
        phoneController.dispose();
        unitController.dispose();
        rankController.dispose();
        rolesController.dispose();
        return;
      }

      await this.context.read<AdminProvider>().updateUser(
        userId: user.id,
        personalNumber: personalNumberController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        unit: unitController.text.trim(),
        rank: rankController.text.trim(),
        roles: _parseCsv(rolesController.text),
      );
    }

    personalNumberController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    unitController.dispose();
    rankController.dispose();
    rolesController.dispose();
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    AdminUserModel user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nutzer löschen'),
          content: Text(
            'Soll ${user.displayName} wirklich gelöscht werden?\n'
            'Hinweis: Bei vorhandenen Abwesenheitsdaten lehnt das Backend das Löschen ab.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) {
        return;
      }

      await this.context.read<AdminProvider>().deleteUser(user.id);
    }
  }

  Future<void> _onIssueTokenPressed(
    AdminProvider admin, {
    required bool hasActiveToken,
  }) async {
    final userId = admin.selectedUserId;
    if (userId == null || !_issueTokenFormKey.currentState!.validate()) {
      return;
    }

    final tokenIdentifier = _issueTokenIdentifierController.text.trim();
    final ok = hasActiveToken && _revokeCurrentActive
        ? await admin.reassignNfcToken(
            userId: userId,
            newTokenIdentifier: tokenIdentifier,
          )
        : await admin.issueNfcToken(
            userId: userId,
            tokenIdentifier: tokenIdentifier,
            revokeCurrentActive: false,
          );

    if (ok) {
      _issueTokenIdentifierController.clear();
    }
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutzerverwaltung'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.manage_accounts), text: 'Verwalten'),
            Tab(icon: Icon(Icons.nfc), text: 'NFC'),
            Tab(icon: Icon(Icons.history), text: 'Protokoll'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, child) {
          AdminUserModel? selectedUser;
          if (admin.selectedUserId != null) {
            for (final user in admin.users) {
              if (user.id == admin.selectedUserId) {
                selectedUser = user;
                break;
              }
            }
          }
          final hasActiveToken = selectedUser?.activeNfcToken != null;

          return Column(
            children: [
              if (admin.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ErrorMessageBox(message: admin.errorMessage!),
                ),
              if (admin.successMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
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
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: admin.loadUsers,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Nutzerliste',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: admin.isLoading
                                    ? null
                                    : admin.loadUsers,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Neu laden',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (admin.isLoading)
                            const LoadingIndicator(message: 'Lade Nutzer...')
                          else if (admin.users.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Keine Nutzer vorhanden.'),
                              ),
                            )
                          else
                            ...admin.users.map((user) {
                              final isProtectedBootstrapAdmin =
                                  user.personalNumber ==
                                  _protectedBootstrapAdminPersonalNumber;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${user.displayName} (${user.personalNumber})',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${user.rank} · ${user.unit}',
                                                ),
                                                const SizedBox(height: 2),
                                                Text(user.email),
                                                const SizedBox(height: 2),
                                                Text(user.phoneNumber),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: user.roles
                                                      .map(
                                                        (role) => Chip(
                                                          label: Text(role),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  user.isActive
                                                      ? 'Status: Aktiv'
                                                      : 'Status: Gesperrt',
                                                  style: TextStyle(
                                                    color: user.isActive
                                                        ? Colors.green.shade800
                                                        : Colors.red.shade800,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (!user.isActive &&
                                                    user.lockReason != null &&
                                                    user.lockReason!
                                                        .trim()
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Sperrgrund: ${user.lockReason}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade900,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                                if (!user.isActive &&
                                                    user.lockedAt != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Gesperrt am: ${_formatDateTime(user.lockedAt!)}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade900,
                                                    ),
                                                  ),
                                                ],
                                                if (user.activeNfcToken !=
                                                    null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Aktiver Token: ${user.activeNfcToken!.tokenIdentifier}',
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await admin.selectUser(user.id);
                                              if (mounted) {
                                                _tabController.animateTo(1);
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.nfc,
                                              size: 18,
                                            ),
                                            label: const Text('NFC'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showEditUserDialog(
                                                  context,
                                                  user,
                                                ),
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Bearbeiten'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showResetPasswordDialog(
                                                  context,
                                                  user,
                                                ),
                                            icon: const Icon(Icons.password),
                                            label: const Text('Passwort reset'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: isProtectedBootstrapAdmin
                                                ? null
                                                : () => user.isActive
                                                      ? admin.blockUser(user.id)
                                                      : admin.unblockUser(
                                                          user.id,
                                                        ),
                                            icon: Icon(
                                              user.isActive
                                                  ? Icons.lock
                                                  : Icons.lock_open,
                                            ),
                                            label: Text(
                                              isProtectedBootstrapAdmin
                                                  ? 'Nicht sperrbar'
                                                  : user.isActive
                                                  ? 'Sperren'
                                                  : 'Entsperren',
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _confirmDeleteUser(
                                              context,
                                              user,
                                            ),
                                            icon: const Icon(
                                              Icons.delete_forever,
                                            ),
                                            label: const Text('Löschen'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: selectedUser == null
                                ? const Text(
                                    'Bitte zuerst im Tab Nutzer einen Nutzer auswählen.',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ausgewählter Nutzer: ${selectedUser.displayName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Personalnummer: ${selectedUser.personalNumber}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedUser.isActive
                                            ? 'Nutzerstatus: Aktiv'
                                            : 'Nutzerstatus: Gesperrt',
                                      ),
                                      if (!selectedUser.isActive &&
                                          selectedUser.lockReason != null &&
                                          selectedUser.lockReason!
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sperrgrund: ${selectedUser.lockReason}',
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (!selectedUser.isActive &&
                                          selectedUser.lockedAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Gesperrt am: ${_formatDateTime(selectedUser.lockedAt!)}',
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: admin.isLoading
                                                ? null
                                                : admin.loadSelectedUserTokens,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text(
                                              'Token neu laden',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedUser != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Form(
                                key: _issueTokenFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasActiveToken
                                          ? 'Token vergeben oder ersetzen'
                                          : 'Token vergeben',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    AppTextField(
                                      label: 'Neuer Token-Identifier',
                                      controller:
                                          _issueTokenIdentifierController,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Pflichtfeld'
                                          : null,
                                    ),
                                    if (hasActiveToken) ...[
                                      const SizedBox(height: 8),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        value: _revokeCurrentActive,
                                        onChanged: (value) {
                                          setState(() {
                                            _revokeCurrentActive = value;
                                          });
                                        },
                                        title: const Text(
                                          'Aktiven Token ersetzen',
                                        ),
                                        subtitle: const Text(
                                          'Deaktiviert den aktuell aktiven Token und vergibt den neuen Identifier.',
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    PrimaryButton(
                                      label:
                                          hasActiveToken && _revokeCurrentActive
                                          ? 'Token ersetzen'
                                          : 'Token vergeben',
                                      isLoading: admin.isSubmitting,
                                      onPressed: () => _onIssueTokenPressed(
                                        admin,
                                        hasActiveToken: hasActiveToken,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Token-Historie (${admin.selectedUserTokens.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (admin.isLoading)
                            const LoadingIndicator(message: 'Lade Token...')
                          else if (admin.selectedUserTokens.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Keine Tokens vorhanden.'),
                              ),
                            )
                          else
                            ...admin.selectedUserTokens.map(
                              (token) => _NfcTokenCard(
                                token: token,
                                formatDateTime: _formatDateTime,
                                onBlock: token.isActive
                                    ? () =>
                                          admin.blockNfcToken(tokenId: token.id)
                                    : null,
                                onDelete: () =>
                                    admin.deleteNfcToken(tokenId: token.id),
                              ),
                            ),
                        ],
                      ],
                    ),
                    _buildAuditLogsTab(admin),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuditLogsTab(AdminProvider admin) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audit-Protokoll',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                // Action Type Filter
                DropdownButton<String?>(
                  value: admin.auditLogsActionFilter,
                  onChanged: (value) {
                    admin.loadAuditLogs(actionType: value);
                  },
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Alle Aktionen'),
                    ),
                    const DropdownMenuItem(
                      value: 'LOGIN',
                      child: Text('Login'),
                    ),
                    const DropdownMenuItem(
                      value: 'NFC',
                      child: Text('NFC-Vorgänge'),
                    ),
                    const DropdownMenuItem(
                      value: 'USER',
                      child: Text('Nutzerverwaltung'),
                    ),
                    const DropdownMenuItem(
                      value: 'PASSWORD',
                      child: Text('Passwortänderungen'),
                    ),
                    const DropdownMenuItem(
                      value: 'ABSENCE',
                      child: Text('Abwesenheitsvorgänge'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (admin.isLoadingAuditLogs)
                  const LoadingIndicator(message: 'Lade Audit-Protokoll...')
                else if (admin.auditLogs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Keine Einträge im Audit-Protokoll.'),
                    ),
                  )
                else ...[
                  ...admin.auditLogs.map((log) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    log.actionType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDateTime(log.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Nutzer: ${log.userDisplay}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (log.actionDetails != null &&
                                log.actionDetails!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Details: ${log.actionDetails}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (log.ipAddress != null &&
                                log.ipAddress!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'IP: ${log.ipAddress}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (admin.auditLogsCurrentPage > 1)
                        OutlinedButton(
                          onPressed: () {
                            admin.loadAuditLogs(
                              page: admin.auditLogsCurrentPage - 1,
                              actionType: admin.auditLogsActionFilter,
                            );
                          },
                          child: const Text('Vorherige'),
                        ),
                      const SizedBox(width: 12),
                      Text(
                        'Seite ${admin.auditLogsCurrentPage} von ${(admin.auditLogsTotal / admin.auditLogsPageSize).ceil()}',
                      ),
                      const SizedBox(width: 12),
                      if (admin.auditLogsCurrentPage <
                          (admin.auditLogsTotal / admin.auditLogsPageSize)
                              .ceil())
                        OutlinedButton(
                          onPressed: () {
                            admin.loadAuditLogs(
                              page: admin.auditLogsCurrentPage + 1,
                              actionType: admin.auditLogsActionFilter,
                            );
                          },
                          child: const Text('Nächste'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NfcTokenCard extends StatelessWidget {
  final AdminNfcTokenModel token;
  final String Function(DateTime) formatDateTime;
  final VoidCallback? onBlock;
  final VoidCallback onDelete;

  const _NfcTokenCard({
    required this.token,
    required this.formatDateTime,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              token.tokenIdentifier,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(token.isActive ? 'Status: Aktiv' : 'Status: Gesperrt'),
            const SizedBox(height: 4),
            Text('Ausgegeben: ${formatDateTime(token.issuedAt)}'),
            if (token.revokedAt != null) ...[
              const SizedBox(height: 2),
              Text('Gesperrt am: ${formatDateTime(token.revokedAt!)}'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onBlock,
                  icon: const Icon(Icons.lock),
                  label: const Text('Sperren'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Löschen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
