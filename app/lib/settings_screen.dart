import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  bool _savingPassword = false;
  bool _exporting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _changePassword() async {
    final pw = _passwordController.text;
    if (pw.length < 6) {
      _msg('Password must be at least 6 characters.');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: pw));
      _passwordController.clear();
      _msg('Password updated.');
    } catch (e) {
      _msg('Could not update password: $e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _exportDreams() async {
    setState(() => _exporting = true);
    try {
      final data =
          await supabase.from('dreams').select().order('created_at');
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: json));
      _msg('Your dreams were copied to the clipboard as JSON.');
    } catch (e) {
      _msg('Could not export: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Account', [
            _row('Email', email),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                hintText: 'Leave blank to keep current',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _savingPassword ? null : _changePassword,
                child: _savingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: onGold))
                    : const Text('Update password'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _section('Your data', [
            Text('Export every dream as JSON (copied to your clipboard).',
                style: TextStyle(color: warmText.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _exportDreams,
              icon: const Icon(Icons.download),
              label: Text(_exporting ? 'Exporting…' : 'Export my dreams'),
            ),
          ]),
          const SizedBox(height: 16),
          _section('Session', [
            OutlinedButton.icon(
              onPressed: () => supabase.auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nightSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: warmText.withValues(alpha: 0.7))),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}