import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../widgets/feature_card.dart';
import '../widgets/stats_widget.dart';
import 'image_editor_page.dart';
import 'background_remover_page.dart';
import 'file_scanner_page.dart';
import 'settings_page.dart';
import 'tools_page.dart';
import '../nova_assistant_page.dart';
import '../network/project_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const ToolsPage(),
    const SettingsPage(),
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
      appBar: AppBar(
        title: Text('EditNova'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => setState(() => _selectedIndex = 2),
          ),
        ],
      ),
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
            label: 'Advanced Commands',
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NovaAssistantPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: const [
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.auto_awesome)),
              title: Text('Nova is ready'),
              subtitle: Text('Create, edit, and organize your next project.'),
            ),
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.tips_and_updates_outlined)),
              title: Text('New tools available'),
              subtitle: Text('Explore the full toolkit from the Tools tab.'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<EditNovaProject> _projects = [];
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await ProjectRepository.list();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _loadingProjects = false;
    });
  }

  Future<void> _createProject() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Project name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await ProjectRepository.create(name);
    await _loadProjects();
  }

  Future<void> _deleteProject(EditNovaProject project) async {
    await ProjectRepository.delete(project.id);
    await _loadProjects();
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projects', style: Theme.of(context).textTheme.headlineMedium),
              IconButton(
                onPressed: _createProject,
                icon: const Icon(Icons.add),
                tooltip: 'Create project',
              ),
            ],
          ),
          if (_loadingProjects)
            const LinearProgressIndicator()
          else if (_projects.isEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open),
              title: const Text('No projects yet'),
              subtitle: const Text('Create a project to keep your work together.'),
              trailing: FilledButton(
                onPressed: _createProject,
                child: const Text('Create'),
              ),
            )
          else
            ..._projects.take(3).map(
                  (project) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(project.name),
                    subtitle: Text('Updated ${project.updatedAt.toLocal()}'),
                    trailing: IconButton(
                      onPressed: () => _deleteProject(project),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete project',
                    ),
                  ),
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
