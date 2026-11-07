import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileScannerPage extends StatefulWidget {
  const FileScannerPage({super.key});

  @override
  State<FileScannerPage> createState() => _FileScannerPageState();
}

class _FileScannerPageState extends State<FileScannerPage> {
  final List<ScannedFile> _scannedFiles = [];

  Future<void> _pickAndScanFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || !mounted) return;

    setState(() {
      for (final file in result.files) {
        _scannedFiles.insert(
          0,
          ScannedFile(
            name: file.name,
            size: file.size,
            extension: file.extension ?? 'unknown',
            isSafe: null,
            threats: [],
            scanTime: null,
            scanDate: DateTime.now(),
          ),
        );
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _scannedFiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'File Scanner',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _scannedFiles.isNotEmpty ? _clearHistory : null,
            tooltip: 'Clear History',
          ),
        ],
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Scanner Status Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.gpp_maybe, size: 50, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Security Scan Unavailable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No scanning service is configured. Selected file contents are not analyzed.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Scan Button
          Container(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _pickAndScanFile,
                icon: Icon(Icons.file_upload),
                label: Text(
                  'Select Files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          // Results Section
          Expanded(
            child: _scannedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No files selected',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Selected files will be marked unverified because no scan service is available.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _scannedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _scannedFiles[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: file.isSafe == null
                                          ? Colors.amber.withValues(alpha: 0.1)
                                          : file.isSafe!
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      file.isSafe == null
                                          ? Icons.help_outline
                                          : file.isSafe!
                                          ? Icons.verified_user
                                          : Icons.warning,
                                      color: file.isSafe == null
                                          ? Colors.amber
                                          : file.isSafe!
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Montserrat',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              _formatFileSize(file.size),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              ' • ',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              file.extension.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        file.isSafe == null
                                            ? 'UNVERIFIED'
                                            : file.isSafe!
                                            ? 'SAFE'
                                            : 'THREAT',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: file.isSafe == null
                                              ? Colors.amber
                                              : file.isSafe!
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Text(
                                        file.scanTime == null
                                            ? 'No verdict'
                                            : '${file.scanTime!.toStringAsFixed(1)}s',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (file.threats.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Threats Detected:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      ...file.threats.map(
                                        (threat) => Text(
                                          '• $threat',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}

class ScannedFile {
  final String name;
  final int size;
  final String extension;
  final bool? isSafe;
  final List<String> threats;
  final double? scanTime;
  final DateTime scanDate;

  ScannedFile({
    required this.name,
    required this.size,
    required this.extension,
    required this.isSafe,
    required this.threats,
    required this.scanTime,
    required this.scanDate,
  });
}
