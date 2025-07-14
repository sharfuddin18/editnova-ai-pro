import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileScannerPage extends StatefulWidget {
  @override
  _FileScannerPageState createState() => _FileScannerPageState();
}

class _FileScannerPageState extends State<FileScannerPage> {
  List<File> _scannedFiles = [];
  bool _isScanning = false;
  int _threatsFound = 0;

  Future<void> _scanFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _isScanning = true;
        _scannedFiles.clear();
        _threatsFound = 0;
      });

      // Simulate scanning process
      for (String? path in result.paths) {
        if (path != null) {
          await Future.delayed(Duration(milliseconds: 500));
          setState(() {
            _scannedFiles.add(File(path));
            // Simulate threat detection (random)
            if (DateTime.now().millisecond % 10 == 0) {
              _threatsFound++;
            }
          });
        }
      }

      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan completed! ${_threatsFound} threats found.'),
          backgroundColor: _threatsFound > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _scannedFiles.clear();
                _threatsFound = 0;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'File Security Scanner',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Scan your files for potential threats and malware',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Files Scanned', _scannedFiles.length.toString()),
                        _buildStatCard('Threats Found', _threatsFound.toString()),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanFiles,
                      icon: _isScanning
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.scanner),
                      label: Text(_isScanning ? 'Scanning...' : 'Select Files to Scan'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Scan Results',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Expanded(
                      child: _scannedFiles.isEmpty
                          ? Center(
                              child: Text(
                                'No files scanned yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _scannedFiles.length,
                              itemBuilder: (context, index) {
                                final file = _scannedFiles[index];
                                final isThreat = index % 10 == 0; // Simulate threat
                                return ListTile(
                                  leading: Icon(
                                    isThreat ? Icons.warning : Icons.check_circle,
                                    color: isThreat ? Colors.red : Colors.green,
                                  ),
                                  title: Text(
                                    file.path.split('/').last,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    isThreat ? 'Potential threat detected' : 'Clean',
                                    style: TextStyle(
                                      color: isThreat ? Colors.red : Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: isThreat
                                      ? IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Quarantine action
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('File quarantined')),
                                            );
                                          },
                                        )
                                      : null,
                                );
                              },
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

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}