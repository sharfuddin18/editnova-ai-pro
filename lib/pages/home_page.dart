import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../widgets/feature_card.dart';
import '../widgets/stats_widget.dart';
import 'image_editor_page.dart';
import 'background_remover_page.dart';
import 'file_scanner_page.dart';
import '../nova_assistant_page.dart';
import '../ai_assistant.dart';

class HomePage extends StatefulWidget {
  final NovaAssistant novaAssistant;

  HomePage({required this.novaAssistant});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeContent(),
    Center(child: Text('Tools', style: TextStyle(fontSize: 24))),
    Center(child: Text('Settings', style: TextStyle(fontSize: 24))),
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit ID
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (_, error) => print('Ad load failed: $error'),
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
      appBar: AppBar(
        title: Text('EditNova'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdLoaded)
            Container(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build),
                label: 'Tools',
              ),
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
              String? command = await widget.novaAssistant.listen();
              if (command != null) {
                await widget.novaAssistant.handleCommand(command);
              }
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
            label: 'Advanced Commands',
            onTap: () async {
              String? command = await widget.novaAssistant.listen();
              if (command != null) {
                await widget.novaAssistant.handleAdvancedCommand(command);
              }
            },
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
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
            'Your AI-powered editing companion',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24),
          StatsWidget(),
          SizedBox(height: 24),
          Text(
            'Features',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
                description: 'Advanced AI image editing',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageEditorPage()),
                ),
              ),
              FeatureCard(
                title: 'Background Remover',
                icon: Icons.layers_clear,
                description: 'Remove backgrounds instantly',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BackgroundRemoverPage()),
                ),
              ),
              FeatureCard(
                title: 'File Scanner',
                icon: Icons.scanner,
                description: 'Scan and organize files',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileScannerPage()),
                ),
              ),
              FeatureCard(
                title: 'Nova Assistant',
                icon: Icons.assistant,
                description: 'AI voice assistant',
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
