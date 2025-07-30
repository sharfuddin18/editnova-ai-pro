import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
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
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/toggle-feature'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'feature': feature, 'enabled': enabled}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Continue with local storage even if API fails
    }
    await _saveSettings();
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unlock premium features:'),
              SizedBox(height: 12),
              _buildPremiumFeature('Unlimited AI art generation'),
              _buildPremiumFeature('Batch processing'),
              _buildPremiumFeature('Cloud synchronization'),
              _buildPremiumFeature('Advanced filters & effects'),
              _buildPremiumFeature('Priority customer support'),
              _buildPremiumFeature('No advertisements'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Special offer: 50% off first month!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildPremiumFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _upgradeToPremium() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/upgrade-premium'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plan': 'monthly'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to EditNova Premium! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upgrade successful! Premium features unlocked.'),
          backgroundColor: Colors.green,
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
                  title: Text(
                    'NovaUser',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('user@editnova.com'),
                  trailing: Icon(Icons.edit),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile editing coming soon!')),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text('Upgrade to Premium'),
                  subtitle: Text('Unlock all features & remove ads'),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '50% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                  subtitle: Text('Receive app notifications'),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() => _notifications = value);
                    _toggleFeature('notifications', value);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.save),
                  title: Text('Auto Save'),
                  subtitle: Text('Automatically save edited images'),
                  value: _autoSave,
                  onChanged: (value) {
                    setState(() => _autoSave = value);
                    _toggleFeature('auto_save', value);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.cloud_sync),
                  title: Text('Cloud Sync'),
                  subtitle: Text('Sync data across devices (Premium)'),
                  value: _cloudSync,
                  onChanged: (value) {
                    setState(() => _cloudSync = value);
                    _toggleFeature('cloud_sync', value);
                  },
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
                  subtitle: Text(_qualityMode),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showQualityDialog(),
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.auto_awesome),
                  title: Text('AI Enhancement'),
                  subtitle: Text('Enable AI-powered improvements'),
                  value: _aiEnhancement,
                  onChanged: (value) {
                    setState(() => _aiEnhancement = value);
                    _toggleFeature('ai_enhancement', value);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.speed),
                  title: Text('Processing Speed'),
                  subtitle: Text('${(_processingSpeed * 100).round()}% speed'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: _processingSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 3,
                      onChanged: (value) {
                        setState(() => _processingSpeed = value);
                      },
                      onChangeEnd: (value) {
                        _toggleFeature('processing_speed', value > 1.0);
                      },
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
                  subtitle: Text(_language),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(),
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
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Help center coming soon!')),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Report Bug'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bug reporting coming soon!')),
                    );
                  },
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
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privacy policy coming soon!')),
                    );
                  },
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

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quality Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Low', 'Medium', 'High', 'Ultra'].map((quality) => 
            RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: _qualityMode,
              onChanged: (value) {
                setState(() => _qualityMode = value!);
                Navigator.pop(context);
                _toggleFeature('quality_mode', value == 'High' || value == 'Ultra');
              },
            )
          ).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German', 'Italian'].map((lang) => 
            RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
                _toggleFeature('language', value != 'English');
              },
            )
          ).toList(),
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
              'EditNova - AI-Powered Editing Suite',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 2025.03.001'),
            SizedBox(height: 12),
            Text(
              'Transform your images with the power of AI. EditNova provides professional-grade editing tools, background removal, file scanning, and much more.',
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
        content: Text('Are you sure you want to reset all settings to default? This action cannot be undone.'),
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