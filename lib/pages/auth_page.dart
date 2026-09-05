import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';
import '../network/auth_session.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty || (_signup && _email.text.trim().isEmpty)) {
      _notify('Complete all required fields.');
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await http.post(
        ApiConfig.endpoint(_signup ? '/api/signup' : '/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username.text.trim(),
          'password': _password.text,
          if (_signup) 'email': _email.text.trim(),
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['message']);
      await AuthSession.save(data['token'].toString(), _username.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _notify('Authentication failed. Check your details and backend connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notify(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_signup ? 'Create account' : 'Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.auto_awesome, size: 56, color: Theme.of(context).primaryColor),
          const SizedBox(height: 18),
          Text(_signup ? 'Join EditNova' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
          if (_signup) ...[
            const SizedBox(height: 14),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          ],
          const SizedBox(height: 14),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
          const SizedBox(height: 22),
          FilledButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Please wait...' : (_signup ? 'Create account' : 'Sign in'))),
          TextButton(onPressed: _loading ? null : () => setState(() => _signup = !_signup), child: Text(_signup ? 'Already have an account? Sign in' : 'New here? Create an account')),
        ],
      ),
    );
  }
}
