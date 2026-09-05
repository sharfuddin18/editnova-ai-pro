import 'package:flutter/material.dart';
import 'package:editnova/network/auth_session.dart';
import 'package:editnova/pages/auth_page.dart';
import 'package:editnova/pages/home_page.dart';
import 'package:editnova/utils/theme.dart';

void main() {
  runApp(const EditNovaApp());
}

class EditNovaApp extends StatelessWidget {
  const EditNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditNova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<bool> _sessionCheck;

  @override
  void initState() {
    super.initState();
    _sessionCheck = _hasSession();
  }

  Future<bool> _hasSession() async {
    final token = await AuthSession.token();
    return token != null && token.isNotEmpty;
  }

  void _onAuthenticated() {
    if (mounted) setState(() => _sessionCheck = Future.value(true));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return const HomePage();
        return AuthPage(onAuthenticated: _onAuthenticated);
      },
    );
  }
}
