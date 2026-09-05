import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_config.dart';

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({super.key});

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  String _selectedType = 'URL';
  String? _generatedQRId;
  bool _isGenerating = false;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _history = prefs.getStringList('qrHistory') ?? []);
  }

  Future<void> _saveHistory(String value) async {
    final updated = [value, ..._history.where((item) => item != value)].take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('qrHistory', updated);
    if (mounted) setState(() => _history = updated);
  }

  final List<QRType> _qrTypes = [
    QRType('URL', Icons.link, 'Website or link'),
    QRType('Text', Icons.text_fields, 'Plain text'),
    QRType('Email', Icons.email, 'Email address'),
    QRType('Phone', Icons.phone, 'Phone number'),
    QRType('WiFi', Icons.wifi, 'WiFi network'),
    QRType('SMS', Icons.sms, 'SMS message'),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
        ApiConfig.endpoint('/api/generate-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'type': _selectedType.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _generatedQRId = data['qrId'];
        });
        await _saveHistory(_textController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('QR generation failed: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate QR code')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _shareQR() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generate a QR code before sharing it.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share QR content'),
        content: SelectableText(_textController.text.trim()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('QR content is ready to share.')),
              );
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQR() async {
    if (_textController.text.trim().isEmpty) return;
    try {
      final painter = QrPainter(
        data: _textController.text.trim(),
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      final imageData = await painter.toImageData(1024);
      if (imageData == null) throw Exception('Could not render QR code');
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/editnova_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(imageData.buffer.asUint8List());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR code saved to $path')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the QR code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Code Generator',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
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
                      children: _qrTypes
                          .map((type) => ChoiceChip(
                                avatar: Icon(type.icon, size: 18),
                                label: Text(type.name),
                                selected: _selectedType == type.name,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedType = type.name);
                                    _textController.clear();
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.qr_code),
                        label: Text(_isGenerating
                            ? 'Generating...'
                            : 'Generate QR Code'),
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
                        child: QrImageView(
                          data: _textController.text.trim(),
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
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
      case 'URL':
        return 'https://example.com';
      case 'Text':
        return 'Enter your text message here...';
      case 'Email':
        return 'user@example.com';
      case 'Phone':
        return '+1234567890';
      case 'WiFi':
        return 'Network name and password';
      case 'SMS':
        return 'Phone number and message';
      default:
        return 'Enter content here...';
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
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No QR codes generated yet.'),
              )
            else
              ..._history.map(
                (value) => ListTile(
                  leading: const Icon(Icons.qr_code, color: Colors.indigo),
                  title: Text(value),
                  subtitle: const Text('Saved on this device'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showHistoryActions(value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHistoryActions(String value) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Use this content'),
              onTap: () {
                _textController.text = value;
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Loaded "$value"')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Remove from history'),
              onTap: () {
                Navigator.pop(context);
                _removeFromHistory(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromHistory(String value) async {
    final updated = _history.where((item) => item != value).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('qrHistory', updated);
    if (!mounted) return;
    setState(() => _history = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from history')),
    );
  }
}

class QRType {
  final String name;
  final IconData icon;
  final String description;

  QRType(this.name, this.icon, this.description);
}
