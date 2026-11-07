import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';

class StatsWidget extends StatefulWidget {
  const StatsWidget({super.key});

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

class _StatsWidgetState extends State<StatsWidget> {
  Map<String, dynamic>? _stats;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await http
          .get(apiUri('usage'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw const FormatException('Usage data is unavailable.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid usage response.');
      }
      if (!mounted) return;
      setState(() {
        _stats = decoded;
        _hasLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stats = null;
        _hasLoaded = true;
      });
    }
  }

  String _value(String key) {
    final value = _stats?[key];
    return value is num ? value.toString() : '—';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: stats == null
            ? Center(
                child: Text(
                  _hasLoaded
                      ? 'Usage statistics unavailable'
                      : 'Loading usage statistics...',
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Active users', _value('active_users')),
                      _buildStatItem('Premium', _value('premium_users')),
                      _buildStatItem(
                        'Backgrounds',
                        _value('background_removed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Files scanned', _value('files_scanned')),
                      _buildStatItem(
                        'Threats blocked',
                        _value('threats_blocked'),
                      ),
                      const SizedBox(width: 80),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
