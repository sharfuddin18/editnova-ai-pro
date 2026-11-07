import 'package:flutter/material.dart';

import '../pages/ai_art_generator_page.dart';
import '../pages/batch_processor_page.dart';
import '../pages/image_color_picker_page.dart';
import '../pages/ocr_scanner_page.dart';
import '../pages/password_generator_page.dart';
import '../pages/poster_creator_page.dart';
import '../pages/qr_generator_page.dart';
import '../pages/text_translator_page.dart';
import '../pages/text_utilities_page.dart';
import '../pages/unit_converter_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI tools'),
            Tab(icon: Icon(Icons.build), text: 'Utilities'),
            Tab(icon: Icon(Icons.batch_prediction), text: 'Batch'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: [
              _toolTile(
                icon: Icons.palette,
                title: 'AI art generator',
                subtitle:
                    'Unavailable: no image-generation provider is configured.',
                onTap: () => _openPage(const AIArtGeneratorPage()),
              ),
              _toolTile(
                icon: Icons.translate,
                title: 'Text translator',
                subtitle:
                    'Translate on-device after downloading language models.',
                onTap: () => _openPage(const TextTranslatorPage()),
              ),
              _toolTile(
                icon: Icons.text_fields,
                title: 'OCR scanner',
                subtitle: 'Recognize Latin text on-device on Android and iOS.',
                onTap: () => _openPage(const OCRScannerPage()),
              ),
              _toolTile(
                icon: Icons.photo_size_select_actual,
                title: 'Poster creator',
                subtitle: 'Create a local poster and export it as a PNG.',
                onTap: () => _openPage(const PosterCreatorPage()),
              ),
            ],
          ),
          ListView(
            children: [
              _toolTile(
                icon: Icons.qr_code,
                title: 'QR code generator',
                subtitle: 'Generate and save a real QR code image.',
                onTap: () => _openPage(const QRGeneratorPage()),
              ),
              _toolTile(
                icon: Icons.security,
                title: 'Password generator',
                subtitle: 'Generate and copy a secure password locally.',
                onTap: () => _openPage(const PasswordGeneratorPage()),
              ),
              _toolTile(
                icon: Icons.straighten,
                title: 'Unit converter',
                subtitle: 'Convert length, weight, and temperature.',
                onTap: () => _openPage(const UnitConverterPage()),
              ),
              _toolTile(
                icon: Icons.text_snippet,
                title: 'Text utilities',
                subtitle: 'Base64, JSON, regex matches, and placeholder text.',
                onTap: () => _openPage(const TextUtilitiesPage()),
              ),
              _toolTile(
                icon: Icons.colorize,
                title: 'Image color picker',
                subtitle: 'Tap an image to sample and copy a pixel color.',
                onTap: () => _openPage(const ImageColorPickerPage()),
              ),
            ],
          ),
          ListView(
            children: [
              _toolTile(
                icon: Icons.photo_size_select_large,
                title: 'Batch image processing',
                subtitle: 'Resize and convert selected images locally.',
                onTap: () => _openPage(const BatchProcessorPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
