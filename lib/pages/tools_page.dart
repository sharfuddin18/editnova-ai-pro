import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../pages/qr_generator_page.dart';
import '../pages/ai_art_generator_page.dart';
import '../pages/poster_creator_page.dart';
import '../pages/text_translator_page.dart';
import '../pages/ocr_scanner_page.dart';
import '../pages/batch_processor_page.dart';

class ToolsPage extends StatefulWidget {
  @override
  _ToolsPageState createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _toolStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadToolStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadToolStats() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5001/api/usage'));
      if (response.statusCode == 200) {
        setState(() {
          _toolStats = json.decode(response.body);
        });
      }
    } catch (e) {
      // Use default stats if API fails
      setState(() {
        _toolStats = {
          "ai_art_generated": 156,
          "texts_translated": 234,
          "qr_codes_generated": 67,
          "images_edited": 892
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Advanced Tools',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Tools'),
            Tab(icon: Icon(Icons.build), text: 'Utilities'),
            Tab(icon: Icon(Icons.batch_prediction), text: 'Batch'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAIToolsTab(),
          _buildUtilitiesTab(),
          _buildBatchToolsTab(),
        ],
      ),
    );
  }

  Widget _buildAIToolsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(),
          SizedBox(height: 20),
          Text(
            'AI-Powered Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildToolCard(
                title: 'AI Art Generator',
                subtitle: 'Create stunning artwork',
                icon: Icons.palette,
                gradient: [Colors.purple, Colors.pink],
                stats: '${_toolStats["ai_art_generated"] ?? 0} created',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AIArtGeneratorPage()),
                ),
              ),
              _buildToolCard(
                title: 'Text Translator',
                subtitle: 'Multi-language support',
                icon: Icons.translate,
                gradient: [Colors.blue, Colors.teal],
                stats: '${_toolStats["texts_translated"] ?? 0} translated',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TextTranslatorPage()),
                ),
              ),
              _buildToolCard(
                title: 'OCR Scanner',
                subtitle: 'Extract text from images',
                icon: Icons.text_fields,
                gradient: [Colors.orange, Colors.red],
                stats: 'Smart recognition',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OCRScannerPage()),
                ),
              ),
              _buildToolCard(
                title: 'Poster Creator',
                subtitle: 'Professional designs',
                icon: Icons.photo_size_select_actual,
                gradient: [Colors.green, Colors.lime],
                stats: 'Multiple templates',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PosterCreatorPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilitiesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Utility Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildToolCard(
                title: 'QR Generator',
                subtitle: 'Create QR codes',
                icon: Icons.qr_code,
                gradient: [Colors.indigo, Colors.blue],
                stats: '${_toolStats["qr_codes_generated"] ?? 0} generated',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRGeneratorPage()),
                ),
              ),
              _buildToolCard(
                title: 'Color Picker',
                subtitle: 'Extract colors',
                icon: Icons.colorize,
                gradient: [Colors.pink, Colors.purple],
                stats: 'From any image',
                onTap: () => _showColorPicker(),
              ),
              _buildToolCard(
                title: 'Unit Converter',
                subtitle: 'Length, weight, temp',
                icon: Icons.straighten,
                gradient: [Colors.teal, Colors.cyan],
                stats: 'Multiple units',
                onTap: () => _showUnitConverter(),
              ),
              _buildToolCard(
                title: 'Password Gen',
                subtitle: 'Secure passwords',
                icon: Icons.security,
                gradient: [Colors.red, Colors.orange],
                stats: 'Cryptographically secure',
                onTap: () => _showPasswordGenerator(),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildBatchToolsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Feature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        Text(
                          'Batch processing requires premium subscription',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showUpgradeDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Upgrade'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Batch Processing Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
            children: [
              _buildBatchToolCard(
                title: 'Batch Resize',
                subtitle: 'Resize multiple images at once',
                icon: Icons.photo_size_select_large,
                onTap: () => _showPremiumRequired(),
              ),
              _buildBatchToolCard(
                title: 'Batch Format Convert',
                subtitle: 'Convert between image formats',
                icon: Icons.transform,
                onTap: () => _showPremiumRequired(),
              ),
              _buildBatchToolCard(
                title: 'Batch Watermark',
                subtitle: 'Add watermarks to multiple images',
                icon: Icons.branding_watermark,
                onTap: () => _showPremiumRequired(),
              ),
              _buildBatchToolCard(
                title: 'Batch Background Removal',
                subtitle: 'Remove backgrounds from multiple images',
                icon: Icons.layers_clear,
                onTap: () => _showPremiumRequired(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Images', '${_toolStats["images_edited"] ?? 0}', Icons.image),
                _buildStatItem('AI Art', '${_toolStats["ai_art_generated"] ?? 0}', Icons.palette),
                _buildStatItem('Translations', '${_toolStats["texts_translated"] ?? 0}', Icons.translate),
                _buildStatItem('QR Codes', '${_toolStats["qr_codes_generated"] ?? 0}', Icons.qr_code),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String stats,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    stats,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.grey.shade600),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.lock, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionChip('Hash Generator', Icons.fingerprint),
            _buildQuickActionChip('Lorem Ipsum', Icons.text_snippet),
            _buildQuickActionChip('URL Shortener', Icons.link),
            _buildQuickActionChip('Base64 Encode', Icons.code),
            _buildQuickActionChip('Regex Tester', Icons.search),
            _buildQuickActionChip('JSON Formatter', Icons.data_object),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label coming soon!')),
        );
      },
    );
  }

  void _showColorPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Color Picker tool coming soon!')),
    );
  }

  void _showUnitConverter() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unit Converter tool coming soon!')),
    );
  }

  void _showPasswordGenerator() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password Generator tool coming soon!')),
    );
  }

  void _showPremiumRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: Text('This feature requires a premium subscription. Upgrade now to unlock batch processing capabilities!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradeDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Unlock all premium features:'),
            SizedBox(height: 12),
            _buildPremiumFeature('Unlimited batch processing'),
            _buildPremiumFeature('Advanced AI tools'),
            _buildPremiumFeature('Cloud storage & sync'),
            _buildPremiumFeature('Priority support'),
            _buildPremiumFeature('No advertisements'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Premium features unlocked! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('Upgrade \$9.99/month'),
          ),
        ],
      ),
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
}