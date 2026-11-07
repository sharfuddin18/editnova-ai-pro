import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../network/api_config.dart';

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({super.key});

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  String _selectedType = 'URL';
  Uint8List? _generatedQRBytes;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter some content')));
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await http.post(
        apiUri('generate-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'type': _selectedType.toLowerCase(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final message = data is Map<String, dynamic> ? data['message'] : null;
        throw Exception(message is String ? message : 'QR generation failed.');
      }
      final encodedImage = data is Map<String, dynamic>
          ? data['imageData']
          : null;
      if (encodedImage is! String) {
        throw const FormatException('The QR service returned no image.');
      }
      final imageBytes = base64Decode(encodedImage);
      if (!mounted) return;
      setState(() => _generatedQRBytes = imageBytes);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('QR code generated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to generate QR code: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _saveQR() async {
    final bytes = _generatedQRBytes;
    if (bytes == null) return;
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save QR code',
        fileName: 'editnova-qr.png',
        bytes: bytes,
      );
      if (!mounted || (path == null && !kIsWeb)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'QR code download started.'
                : 'QR code saved to $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save QR code: $error')));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Code Generator',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
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
                      children: _qrTypes
                          .map(
                            (type) => ChoiceChip(
                              avatar: Icon(type.icon, size: 18),
                              label: Text(type.name),
                              selected: _selectedType == type.name,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedType = type.name);
                                  _textController.clear();
                                }
                              },
                            ),
                          )
                          .toList(),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.qr_code),
                        label: Text(
                          _isGenerating ? 'Generating...' : 'Generate QR Code',
                        ),
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
            if (_generatedQRBytes != null) ...[
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
                      Image.memory(
                        _generatedQRBytes!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saveQR,
                        icon: Icon(Icons.download),
                        label: Text('Save QR Code'),
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
      case 'URL':
        return 'https://example.com';
      case 'Text':
        return 'Enter your text message here...';
      case 'Email':
        return 'user@example.com';
      case 'Phone':
        return '+1234567890';
      case 'WiFi':
        return 'Network name|password';
      case 'SMS':
        return 'Phone number|message';
      default:
        return 'Enter content here...';
    }
  }
}

class QRType {
  final String name;
  final IconData icon;
  final String description;

  QRType(this.name, this.icon, this.description);
}
