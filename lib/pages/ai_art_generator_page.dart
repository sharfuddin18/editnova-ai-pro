import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIArtGeneratorPage extends StatefulWidget {
  @override
  _AIArtGeneratorPageState createState() => _AIArtGeneratorPageState();
}

class _AIArtGeneratorPageState extends State<AIArtGeneratorPage>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  String _selectedStyle = 'Abstract';
  bool _isGenerating = false;
  String? _generatedArtId;
  late AnimationController _generateController;
  late AnimationController _pulseController;

  final List<ArtStyle> _artStyles = [
    ArtStyle('Abstract', Icons.blur_on, Colors.purple),
    ArtStyle('Realistic', Icons.landscape, Colors.green),
    ArtStyle('Cartoon', Icons.emoji_emotions, Colors.orange),
    ArtStyle('Oil Painting', Icons.brush, Colors.brown),
    ArtStyle('Watercolor', Icons.water_drop, Colors.blue),
    ArtStyle('Digital', Icons.computer, Colors.teal),
  ];

  @override
  void initState() {
    super.initState();
    _generateController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _generateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateArt() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    _generateController.repeat();
    _pulseController.repeat(reverse: true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/generate-art'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _promptController.text,
          'style': _selectedStyle.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Future.delayed(Duration(seconds: 3)); // Simulate generation time
        
        setState(() {
          _generatedArtId = data['artId'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI artwork generated successfully! 🎨'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate artwork')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
      _generateController.stop();
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Art Generator',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () => _showArtGallery(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generation Status
            if (_isGenerating) ...[
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: _generateController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _generateController.value * 6.28,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 40,
                                      color: Colors.purple,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'AI is creating your artwork...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This may take a few moments',
                        style: TextStyle(
                          color: Colors.purple.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Prompt Input
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Describe Your Artwork',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g., A majestic mountain landscape with flowing waterfalls and vibrant sunset colors...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => _promptController.clear(),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        'Fantasy castle', 'Cyberpunk city', 'Peaceful garden',
                        'Abstract colors', 'Ocean waves', 'Space nebula'
                      ].map((prompt) => 
                        GestureDetector(
                          onTap: () => _promptController.text = prompt,
                          child: Chip(
                            label: Text(prompt, style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.purple.shade100,
                          ),
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Art Style Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Art Style',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _artStyles.length,
                      itemBuilder: (context, index) {
                        final style = _artStyles[index];
                        final isSelected = _selectedStyle == style.name;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStyle = style.name),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? style.color.withOpacity(0.2)
                                : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected ? style.color : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  style.icon,
                                  color: isSelected ? style.color : Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  style.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? style.color : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateArt,
                icon: _isGenerating 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Generating Artwork...' : 'Generate AI Art',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Generated Artwork Display
            if (_generatedArtId != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Your AI Artwork',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade100, Colors.pink.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.purple.shade300,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'AI Generated Artwork',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.purple.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedStyle + ' Style',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _saveArtwork(),
                            icon: Icon(Icons.save),
                            label: Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _shareArtwork(),
                            icon: Icon(Icons.share),
                            label: Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _regenerateArt(),
                            icon: Icon(Icons.refresh),
                            label: Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveArtwork() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Artwork saved to gallery!')),
    );
  }

  void _shareArtwork() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Artwork shared successfully!')),
    );
  }

  void _regenerateArt() {
    setState(() {
      _generatedArtId = null;
    });
    _generateArt();
  }

  void _showArtGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'AI Art Gallery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.primaries[index % Colors.primaries.length].shade200,
                          Colors.primaries[index % Colors.primaries.length].shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 40, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Artwork #${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtStyle {
  final String name;
  final IconData icon;
  final Color color;

  ArtStyle(this.name, this.icon, this.color);
}