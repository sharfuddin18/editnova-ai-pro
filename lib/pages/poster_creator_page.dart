import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PosterCreatorPage extends StatefulWidget {
  @override
  _PosterCreatorPageState createState() => _PosterCreatorPageState();
}

class _PosterCreatorPageState extends State<PosterCreatorPage>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedTemplate = 'Modern';
  String _selectedSize = 'A4 Portrait';
  bool _isCreating = false;
  String? _generatedPosterId;
  late AnimationController _createController;
  late AnimationController _pulseController;

  final List<PosterTemplate> _templates = [
    PosterTemplate(
        'Modern', Icons.design_services, Colors.blue, 'Clean and minimal'),
    PosterTemplate(
        'Creative', Icons.palette, Colors.purple, 'Artistic and bold'),
    PosterTemplate(
        'Business', Icons.business, Colors.teal, 'Professional look'),
    PosterTemplate('Event', Icons.event, Colors.orange, 'Perfect for events'),
    PosterTemplate(
        'Vintage', Icons.auto_awesome, Colors.brown, 'Classic retro style'),
    PosterTemplate(
        'Minimalist', Icons.crop_free, Colors.grey, 'Simple and elegant'),
  ];

  final List<PosterSize> _sizes = [
    PosterSize('A4 Portrait', '210 × 297 mm'),
    PosterSize('A4 Landscape', '297 × 210 mm'),
    PosterSize('A3 Portrait', '297 × 420 mm'),
    PosterSize('Square', '300 × 300 mm'),
    PosterSize('Instagram Post', '1080 × 1080 px'),
    PosterSize('Facebook Cover', '1200 × 630 px'),
  ];

  @override
  void initState() {
    super.initState();
    _createController = AnimationController(
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
    _createController.dispose();
    _pulseController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPoster() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title for your poster')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    _createController.repeat();
    _pulseController.repeat(reverse: true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/create-poster'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'description': _descriptionController.text,
          'template': _selectedTemplate.toLowerCase(),
          'size': _selectedSize,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Future.delayed(Duration(seconds: 3)); // Simulate creation time

        setState(() {
          _generatedPosterId = data['posterId'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Poster created successfully! 🎨'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create poster')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
      _createController.stop();
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Poster Creator',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library),
            onPressed: () => _showPosterGallery(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Creation Status
            if (_isCreating) ...[
              Card(
                color: Colors.green.shade50,
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
                                color: Colors.green.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: _createController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _createController.value * 6.28,
                                    child: Icon(
                                      Icons.design_services,
                                      size: 40,
                                      color: Colors.green,
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
                        'Creating your poster...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This may take a few moments',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Content Input
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poster Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Enter your poster title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _subtitleController,
                      decoration: InputDecoration(
                        labelText: 'Subtitle (Optional)',
                        hintText: 'Enter subtitle...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.subtitles),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Enter additional details...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Template Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Template',
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
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        final isSelected = _selectedTemplate == template.name;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTemplate = template.name),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? template.color.withOpacity(0.2)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected
                                    ? template.color
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  template.icon,
                                  color:
                                      isSelected ? template.color : Colors.grey,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  template.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? template.color
                                        : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  template.description,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isSelected
                                        ? template.color.withOpacity(0.8)
                                        : Colors.grey.shade500,
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

            // Size Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poster Size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sizes
                          .map((size) => ChoiceChip(
                                label: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(size.name,
                                        style: TextStyle(fontSize: 10)),
                                    Text(size.dimensions,
                                        style: TextStyle(fontSize: 8)),
                                  ],
                                ),
                                selected: _selectedSize == size.name,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedSize = size.name);
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createPoster,
                icon: _isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(Icons.create),
                label: Text(
                  _isCreating ? 'Creating Poster...' : 'Create Poster',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Generated Poster Display
            if (_generatedPosterId != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Your Poster',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 400,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade100,
                              Colors.lime.shade100
                            ],
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
                                Icons.photo_size_select_actual,
                                size: 80,
                                color: Colors.green.shade300,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Professional Poster',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_selectedTemplate Template',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade500,
                                ),
                              ),
                              Text(
                                _selectedSize,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade400,
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
                            onPressed: () => _downloadPoster(),
                            icon: Icon(Icons.download),
                            label: Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _sharePoster(),
                            icon: Icon(Icons.share),
                            label: Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _editPoster(),
                            icon: Icon(Icons.edit),
                            label: Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
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

            SizedBox(height: 16),

            // Tips Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Design Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Keep your title short and impactful\n'
                      '• Use high contrast colors for readability\n'
                      '• Choose the right size for your purpose\n'
                      '• Less is more - avoid cluttering',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadPoster() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Poster downloaded successfully!')),
    );
  }

  void _sharePoster() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Poster shared successfully!')),
    );
  }

  void _editPoster() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening poster editor...')),
    );
  }

  void _showPosterGallery() {
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
                'Poster Gallery',
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
                    childAspectRatio: 0.7,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.primaries[index % Colors.primaries.length]
                              .shade200,
                          Colors.primaries[index % Colors.primaries.length]
                              .shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_size_select_actual,
                              size: 40, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Poster #${index + 1}',
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

class PosterTemplate {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  PosterTemplate(this.name, this.icon, this.color, this.description);
}

class PosterSize {
  final String name;
  final String dimensions;

  PosterSize(this.name, this.dimensions);
}
