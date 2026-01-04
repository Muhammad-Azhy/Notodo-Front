import 'package:flutter/material.dart';
import 'package:front/Services/api_services.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final ApiService api = ApiService();

  bool loading = true;
  Map<String, dynamic>? user;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await api.getProfile();
      if (!mounted) return;

      user = data;
      _nameCtrl.text = (data['name'] ?? '').toString();
      _emailCtrl.text = (data['email'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();

      // only send password if user typed it
      final pass = _passCtrl.text.trim();
      final pass2 = _pass2Ctrl.text.trim();

      if (pass.isNotEmpty && pass != pass2) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
        return;
      }

      final res = await api.updateProfile(
        name: name,
        email: email,
        password: pass.isEmpty ? null : pass,
        passwordConfirmation: pass.isEmpty ? null : pass2,
      );

      if (!mounted) return;

      // backend response: {message, user}
      final updated = (res['user'] ?? res) as Map<String, dynamic>;
      user = updated;

      _passCtrl.clear();
      _pass2Ctrl.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }
  }

  Future<void> _confirmDelete() async {
    final pw = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This will permanently delete your account."),
            const SizedBox(height: 12),
            TextField(
              controller: pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Delete",
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await api.deleteAccount(password: pw.text.trim());
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Account deleted")));

      // Go back to login (adjust route name if you use named routes)
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyMedium?.color,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Account Info",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: "Name"),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: "Email"),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Change Password (optional)",
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "New password",
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pass2Ctrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Confirm new password",
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _save,
                            child: const Text("Save Changes"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        "Delete Account",
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      onPressed: _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
