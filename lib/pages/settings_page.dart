import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onDarkModeChanged});

  final ValueChanged<bool>? onDarkModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoSave = true;
  bool _cloudSync = false;
  bool _highQuality = true;
  bool _aiEnhancement = true;
  bool _voiceCommands = true;
  String _language = 'English';
  String _qualityMode = 'High';
  double _processingSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _autoSave = prefs.getBool('autoSave') ?? true;
      _cloudSync = prefs.getBool('cloudSync') ?? false;
      _highQuality = prefs.getBool('highQuality') ?? true;
      _aiEnhancement = prefs.getBool('aiEnhancement') ?? true;
      _voiceCommands = prefs.getBool('voiceCommands') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _qualityMode = prefs.getString('qualityMode') ?? 'High';
      _processingSpeed = prefs.getDouble('processingSpeed') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('autoSave', _autoSave);
    await prefs.setBool('cloudSync', _cloudSync);
    await prefs.setBool('highQuality', _highQuality);
    await prefs.setBool('aiEnhancement', _aiEnhancement);
    await prefs.setBool('voiceCommands', _voiceCommands);
    await prefs.setString('language', _language);
    await prefs.setString('qualityMode', _qualityMode);
    await prefs.setDouble('processingSpeed', _processingSpeed);
  }

  Future<void> _toggleFeature(String feature, bool enabled) async {
    await _saveSettings();
    if (feature == 'dark_mode') widget.onDarkModeChanged?.call(enabled);
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Upgrade to Premium'),
            ],
          ),
          content: const Text(
            'Premium purchases are unavailable because no payment provider is configured. No purchase will be made.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _upgradeToPremium();
              },
              icon: Icon(Icons.star),
              label: Text('Upgrade Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _upgradeToPremium() async {
    try {
      final response = await http.post(
        apiUri('upgrade-premium'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plan': 'monthly'}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['status'] == 'success' &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to EditNova Premium! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        final message = data is Map<String, dynamic> ? data['message'] : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message is String
                  ? message
                  : 'Premium upgrades are unavailable. No purchase was made.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not contact the upgrade service. No purchase was made.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account & Profile'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text('Local profile'),
                  subtitle: Text('Sign-in is not configured'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text('Upgrade to Premium'),
                  subtitle: Text('Purchases are currently unavailable'),
                  onTap: _showUpgradeDialog,
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // App Settings
          _buildSectionHeader('App Settings'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.dark_mode),
                  title: Text('Dark Mode'),
                  subtitle: Text('Use dark theme'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    _toggleFeature('dark_mode', value);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.notifications),
                  title: Text('Notifications'),
                  subtitle: Text(
                    'Unavailable: notification delivery is not implemented',
                  ),
                  value: _notifications,
                  onChanged: null,
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.save),
                  title: Text('Auto Save'),
                  subtitle: Text('Automatic export is not implemented'),
                  value: _autoSave,
                  onChanged: null,
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.cloud_sync),
                  title: Text('Cloud Sync'),
                  subtitle: Text(
                    'Unavailable: no cloud-sync service is configured',
                  ),
                  value: _cloudSync,
                  onChanged: null,
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Processing Settings
          _buildSectionHeader('Processing & Quality'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.high_quality),
                  title: Text('Quality Mode'),
                  subtitle: Text('$_qualityMode (not used by current tools)'),
                  trailing: const Icon(Icons.info_outline, size: 16),
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.auto_awesome),
                  title: Text('AI Enhancement'),
                  subtitle: Text(
                    'Unavailable: no AI enhancement provider is configured',
                  ),
                  value: _aiEnhancement,
                  onChanged: null,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.speed),
                  title: Text('Processing Speed'),
                  subtitle: Text('Not used by current image operations'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: _processingSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 3,
                      onChanged: null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // AI Features
          _buildSectionHeader('AI Features'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.mic),
                  title: Text('Voice Commands'),
                  subtitle: Text('Enable voice control'),
                  value: _voiceCommands,
                  onChanged: (value) {
                    setState(() => _voiceCommands = value);
                    _toggleFeature('voice_commands', value);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  subtitle: Text('$_language (app interface remains English)'),
                  trailing: const Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Support & Info
          _buildSectionHeader('Support & Information'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Help & FAQ'),
                  subtitle: Text('Help content is not available in this build'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Report Bug'),
                  subtitle: Text('No bug-reporting service is configured'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About EditNova'),
                  subtitle: Text('Version 1.0.0'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAboutDialog(),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy Policy'),
                  subtitle: Text('A privacy policy has not been provided'),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Reset Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showResetDialog(),
              icon: Icon(Icons.refresh),
              label: Text('Reset All Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.teal),
            SizedBox(width: 8),
            Text('About EditNova'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EditNova - image editing and utility tools',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 12),
            Text(
              'EditNova currently supports local image adjustments, flat-color background removal, on-device OCR and translation, poster design, batch image resize and conversion, and QR generation. AI generation, security scanning, payments, and analytics require integrations that are not configured in this build.',
            ),
            SizedBox(height: 12),
            Text(
              'Developed with ❤️ using Flutter',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset All Settings'),
        content: Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _loadSettings();
              if (!context.mounted) return;
              widget.onDarkModeChanged?.call(false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Settings reset to default')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
