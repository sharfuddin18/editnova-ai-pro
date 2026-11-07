import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../widgets/feature_card.dart';
import '../widgets/stats_widget.dart';
import 'image_editor_page.dart';
import 'background_remover_page.dart';
import 'file_scanner_page.dart';
import '../nova_assistant_page.dart';
import 'tools_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onDarkModeChanged});

  final ValueChanged<bool>? onDarkModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const ToolsPage(),
      SettingsPage(onDarkModeChanged: widget.onDarkModeChanged),
    ];
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit ID
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (_, error) {},
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EditNova')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdLoaded)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).primaryColor,
        children: [
          SpeedDialChild(
            child: Icon(Icons.mic),
            label: 'Voice Assistant',
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NovaAssistantPage(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.image),
            label: 'Quick Edit',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ImageEditorPage()),
            ),
          ),
          SpeedDialChild(
            child: Icon(Icons.auto_awesome),
            label: 'Voice Assistant',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NovaAssistantPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to EditNova',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Image editing, file tools, and voice controls',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24),
          StatsWidget(),
          SizedBox(height: 24),
          Text('Features', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              FeatureCard(
                title: 'Image Editor',
                icon: Icons.photo_filter,
                description: 'Adjust brightness, contrast, and saturation',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageEditorPage()),
                ),
              ),
              FeatureCard(
                title: 'Flat Background Remover',
                icon: Icons.layers_clear,
                description: 'Remove flat, edge-connected backgrounds locally',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackgroundRemoverPage(),
                  ),
                ),
              ),
              FeatureCard(
                title: 'File Scanner',
                icon: Icons.scanner,
                description: 'File contents are not scanned for threats',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileScannerPage()),
                ),
              ),
              FeatureCard(
                title: 'Nova Assistant',
                icon: Icons.assistant,
                description: 'Speech input with local keyword responses',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NovaAssistantPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
