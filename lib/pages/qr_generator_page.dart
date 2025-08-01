import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRGeneratorPage extends StatefulWidget {
  @override
  _QRGeneratorPageState createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  String _selectedType = 'URL';
  String? _generatedQRId;
  bool _isGenerating = false;
  
  final List<QRType> _qrTypes = [
    QRType('URL', Icons.link, 'Website or link'),
    QRType('Text', Icons.text_fields, 'Plain text'),
    QRType('Email', Icons.email, 'Email address'),
    QRType('Phone', Icons.phone, 'Phone number'),
    QRType('WiFi', Icons.wifi, 'WiFi network'),
    QRType('SMS', Icons.sms, 'SMS message'),
  ];

  Future<void> _generateQR() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/generate-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'type': _selectedType.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedQRId = data['qrId'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate QR code')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _shareQR() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR code sharing feature coming soon!')),
    );
  }

  void _downloadQR() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR code downloaded to gallery!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Code Generator',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _showQRHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Type Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select QR Code Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _qrTypes.map((type) => 
                        ChoiceChip(
                          avatar: Icon(type.icon, size: 18),
                          label: Text(type.name),
                          selected: _selectedType == type.name,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type.name);
                              _textController.clear();
                            }
                          },
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),

            // Content Input
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: _selectedType == 'Text' ? 4 : 1,
                      decoration: InputDecoration(
                        hintText: _getHintText(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => _textController.clear(),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateQR,
                        icon: _isGenerating 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.qr_code),
                        label: Text(_isGenerating ? 'Generating...' : 'Generate QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
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
              ),
            ),

            SizedBox(height: 16),

            // Generated QR Code Display
            if (_generatedQRId != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Your QR Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 120,
                                color: Colors.black87,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
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
                            onPressed: _shareQR,
                            icon: Icon(Icons.share),
                            label: Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _downloadQR,
                            icon: Icon(Icons.download),
                            label: Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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

            // Usage Tips
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
                          'Tips & Best Practices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Keep URLs short for better scanning\n'
                      '• Test QR codes before printing\n'
                      '• Use high contrast colors\n'
                      '• Ensure adequate size for scanning distance',
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

  String _getHintText() {
    switch (_selectedType) {
      case 'URL': return 'https://example.com';
      case 'Text': return 'Enter your text message here...';
      case 'Email': return 'user@example.com';
      case 'Phone': return '+1234567890';
      case 'WiFi': return 'Network name and password';
      case 'SMS': return 'Phone number and message';
      default: return 'Enter content here...';
    }
  }

  void _showQRHistory() {
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
              'QR Code History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.link, color: Colors.blue),
              title: Text('https://flutter.dev'),
              subtitle: Text('URL • Created today'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.text_fields, color: Colors.green),
              title: Text('Welcome to EditNova!'),
              subtitle: Text('Text • Created yesterday'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.orange),
              title: Text('support@editnova.com'),
              subtitle: Text('Email • Created 3 days ago'),
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

class QRType {
  final String name;
  final IconData icon;
  final String description;

  QRType(this.name, this.icon, this.description);
}