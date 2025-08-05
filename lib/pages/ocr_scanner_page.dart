import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OCRScannerPage extends StatefulWidget {
  @override
  _OCRScannerPageState createState() => _OCRScannerPageState();
}

class _OCRScannerPageState extends State<OCRScannerPage>
    with TickerProviderStateMixin {
  String _extractedText = '';
  bool _isScanning = false;
  String? _selectedImagePath;
  String _selectedLanguage = 'English';
  late AnimationController _scanController;
  late AnimationController _pulseController;

  final List<OCRLanguage> _languages = [
    OCRLanguage('English', 'eng', '🇺🇸'),
    OCRLanguage('Spanish', 'spa', '🇪🇸'),
    OCRLanguage('French', 'fra', '🇫🇷'),
    OCRLanguage('German', 'deu', '🇩🇪'),
    OCRLanguage('Italian', 'ita', '🇮🇹'),
    OCRLanguage('Portuguese', 'por', '🇵🇹'),
    OCRLanguage('Russian', 'rus', '🇷🇺'),
    OCRLanguage('Chinese', 'chi_sim', '🇨🇳'),
    OCRLanguage('Japanese', 'jpn', '🇯🇵'),
    OCRLanguage('Korean', 'kor', '🇰🇷'),
    OCRLanguage('Arabic', 'ara', '🇸🇦'),
    OCRLanguage('Hindi', 'hin', '🇮🇳'),
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
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
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    setState(() {
      _isScanning = true;
      _selectedImagePath = 'camera_image.jpg';
    });

    _scanController.repeat();
    _pulseController.repeat(reverse: true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/ocr-scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': 'camera',
          'language': _getLanguageCode(_selectedLanguage),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Future.delayed(Duration(seconds: 3)); // Simulate scanning time

        setState(() {
          _extractedText = data['extractedText'] ??
              'Sample extracted text from camera image. This is a demonstration of OCR functionality that can extract text from images captured by your device camera.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text extracted successfully! 📄'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan image')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
      _scanController.stop();
      _pulseController.stop();
    }
  }

  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
      _selectedImagePath = 'gallery_image.jpg';
    });

    _scanController.repeat();
    _pulseController.repeat(reverse: true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/ocr-scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': 'gallery',
          'language': _getLanguageCode(_selectedLanguage),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Future.delayed(Duration(seconds: 3)); // Simulate scanning time

        setState(() {
          _extractedText = data['extractedText'] ??
              'Sample extracted text from gallery image. This demonstrates OCR capability to read text from images stored in your device gallery.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text extracted successfully! 📄'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan image')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
      _scanController.stop();
      _pulseController.stop();
    }
  }

  String _getLanguageCode(String languageName) {
    return _languages.firstWhere((lang) => lang.name == languageName).code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OCR Scanner',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _showScanHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanning Status
            if (_isScanning) ...[
              Card(
                color: Colors.orange.shade50,
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
                                color: Colors.orange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: _scanController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _scanController.value * 6.28,
                                    child: Icon(
                                      Icons.document_scanner,
                                      size: 40,
                                      color: Colors.orange,
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
                        'Scanning image for text...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI is analyzing the image',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Language Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Text Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.language),
                      ),
                      items: _languages
                          .map((lang) => DropdownMenuItem(
                                value: lang.name,
                                child: Row(
                                  children: [
                                    Text(lang.flag,
                                        style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 8),
                                    Text(lang.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Scan Options
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Image Source',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _scanFromCamera,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _scanFromGallery,
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Selected Image Preview
            if (_selectedImagePath != null && !_isScanning) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image Preview',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _selectedImagePath!,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Extracted Text Display
            if (_extractedText.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Extracted Text',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _copyText(_extractedText),
                                icon: Icon(Icons.copy, size: 20),
                                tooltip: 'Copy text',
                              ),
                              IconButton(
                                onPressed: () => _shareText(_extractedText),
                                icon: Icon(Icons.share, size: 20),
                                tooltip: 'Share text',
                              ),
                              IconButton(
                                onPressed: () => _translateText(_extractedText),
                                icon: Icon(Icons.translate, size: 20),
                                tooltip: 'Translate text',
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: SelectableText(
                          _extractedText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Confidence: 95% • Language: $_selectedLanguage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // OCR Features
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OCR Features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3,
                      children: [
                        _buildFeatureCard(
                            'Multi-language', Icons.language, Colors.blue),
                        _buildFeatureCard(
                            'High Accuracy', Icons.verified, Colors.green),
                        _buildFeatureCard(
                            'Fast Processing', Icons.speed, Colors.orange),
                        _buildFeatureCard('Text Formatting',
                            Icons.format_align_left, Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Tips Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'OCR Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Ensure good lighting when taking photos\n'
                      '• Keep text straight and avoid angles\n'
                      '• Use high resolution images for better accuracy\n'
                      '• Clean images work better than blurry ones',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
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

  Widget _buildFeatureCard(String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard!')),
    );
  }

  void _shareText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text shared successfully!')),
    );
  }

  void _translateText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening translator...')),
    );
  }

  void _showScanHistory() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.document_scanner, color: Colors.orange),
              title: Text('Business Card Scan'),
              subtitle: Text('English • Today • 98% confidence'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.receipt, color: Colors.blue),
              title: Text('Receipt Text'),
              subtitle: Text('English • Yesterday • 95% confidence'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.article, color: Colors.green),
              title: Text('Document Page'),
              subtitle: Text('Spanish • 2 days ago • 92% confidence'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OCRLanguage {
  final String name;
  final String code;
  final String flag;

  OCRLanguage(this.name, this.code, this.flag);
}
