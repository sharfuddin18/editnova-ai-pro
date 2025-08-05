import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BatchProcessorPage extends StatefulWidget {
  @override
  _BatchProcessorPageState createState() => _BatchProcessorPageState();
}

class _BatchProcessorPageState extends State<BatchProcessorPage>
    with TickerProviderStateMixin {
  List<BatchItem> _batchItems = [];
  String _selectedOperation = 'Resize';
  bool _isProcessing = false;
  int _processedCount = 0;
  late AnimationController _processController;
  late AnimationController _progressController;

  final List<BatchOperation> _operations = [
    BatchOperation(
        'Resize', Icons.photo_size_select_large, 'Resize multiple images'),
    BatchOperation('Format Convert', Icons.transform, 'Convert image formats'),
    BatchOperation('Watermark', Icons.branding_watermark, 'Add watermarks'),
    BatchOperation(
        'Background Remove', Icons.layers_clear, 'Remove backgrounds'),
    BatchOperation('Compress', Icons.compress, 'Compress file sizes'),
    BatchOperation('Filter Apply', Icons.filter, 'Apply image filters'),
  ];

  @override
  void initState() {
    super.initState();
    _processController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _processController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _addFiles() {
    setState(() {
      _batchItems.addAll([
        BatchItem('image1.jpg', 'Image', 2.5, BatchStatus.pending),
        BatchItem('image2.png', 'Image', 1.8, BatchStatus.pending),
        BatchItem('document.pdf', 'Document', 0.9, BatchStatus.pending),
        BatchItem('photo.jpeg', 'Image', 3.2, BatchStatus.pending),
      ]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_batchItems.length} files added to batch')),
    );
  }

  void _removeFile(int index) {
    setState(() {
      _batchItems.removeAt(index);
    });
  }

  Future<void> _startBatchProcessing() async {
    if (_batchItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add files to process')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
    });

    _processController.repeat();

    try {
      for (int i = 0; i < _batchItems.length; i++) {
        setState(() {
          _batchItems[i].status = BatchStatus.processing;
        });

        // Simulate processing time
        await Future.delayed(Duration(seconds: 2));

        final response = await http.post(
          Uri.parse('http://localhost:5001/api/batch-process'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'operation': _selectedOperation.toLowerCase(),
            'filename': _batchItems[i].name,
            'type': _batchItems[i].type,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            _batchItems[i].status = BatchStatus.completed;
            _processedCount++;
          });
        } else {
          setState(() {
            _batchItems[i].status = BatchStatus.failed;
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch processing completed! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch processing failed')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _processController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Batch Processor',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showBatchSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Notice
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Feature',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          Text(
                            'Batch processing requires premium subscription',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showUpgradeDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Upgrade'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Operation Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Operation',
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
                      itemCount: _operations.length,
                      itemBuilder: (context, index) {
                        final operation = _operations[index];
                        final isSelected = _selectedOperation == operation.name;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedOperation = operation.name),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.deepPurple.withOpacity(0.2)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  operation.icon,
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  operation.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.deepPurple
                                        : Colors.grey.shade600,
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

            // File Management
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
                          'Files (${_batchItems.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _addFiles,
                              icon: Icon(Icons.add, size: 16),
                              label: Text('Add Files'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: Size(100, 32),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _batchItems.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _batchItems.clear();
                                      });
                                    },
                              icon: Icon(Icons.clear_all, size: 16),
                              label: Text('Clear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: Size(80, 32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_batchItems.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_upload,
                                size: 48, color: Colors.grey.shade400),
                            SizedBox(height: 8),
                            Text(
                              'No files added yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Click "Add Files" to get started',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _batchItems.length,
                        itemBuilder: (context, index) {
                          final item = _batchItems[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(item.status),
                                child: Icon(
                                  _getStatusIcon(item.status),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${item.type} • ${item.size.toStringAsFixed(1)} MB',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getStatusText(item.status),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getStatusColor(item.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  if (item.status == BatchStatus.processing)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    IconButton(
                                      onPressed: () => _removeFile(index),
                                      icon: Icon(Icons.close, size: 16),
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

            // Processing Progress
            if (_isProcessing) ...[
              Card(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _processController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _processController.value * 6.28,
                            child: Icon(
                              Icons.settings,
                              size: 40,
                              color: Colors.deepPurple,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing Files...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$_processedCount of ${_batchItems.length} completed',
                        style: TextStyle(
                          color: Colors.deepPurple.shade600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _batchItems.isEmpty
                            ? 0
                            : _processedCount / _batchItems.length,
                        backgroundColor: Colors.deepPurple.shade100,
                        valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Process Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (_isProcessing || _batchItems.isEmpty)
                    ? null
                    : _startBatchProcessing,
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(Icons.play_arrow),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Start Batch Processing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Statistics
            if (_batchItems.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total Files', '${_batchItems.length}',
                              Icons.folder),
                          _buildStatItem('Completed', '$_processedCount',
                              Icons.check_circle),
                          _buildStatItem(
                              'Failed',
                              '${_batchItems.where((item) => item.status == BatchStatus.failed).length}',
                              Icons.error),
                          _buildStatItem(
                              'Pending',
                              '${_batchItems.where((item) => item.status == BatchStatus.pending).length}',
                              Icons.pending),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.pending:
        return Colors.grey;
      case BatchStatus.processing:
        return Colors.blue;
      case BatchStatus.completed:
        return Colors.green;
      case BatchStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BatchStatus status) {
    switch (status) {
      case BatchStatus.pending:
        return Icons.pending;
      case BatchStatus.processing:
        return Icons.refresh;
      case BatchStatus.completed:
        return Icons.check;
      case BatchStatus.failed:
        return Icons.error;
    }
  }

  String _getStatusText(BatchStatus status) {
    switch (status) {
      case BatchStatus.pending:
        return 'Pending';
      case BatchStatus.processing:
        return 'Processing';
      case BatchStatus.completed:
        return 'Completed';
      case BatchStatus.failed:
        return 'Failed';
    }
  }

  void _showBatchSettings() {
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
              'Batch Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.speed),
              title: Text('Processing Speed'),
              subtitle: Text('Fast processing mode'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('Auto Backup'),
              subtitle: Text('Backup original files'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              subtitle: Text('Notify when complete'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Unlock batch processing features:'),
            SizedBox(height: 12),
            _buildPremiumFeature('Process unlimited files'),
            _buildPremiumFeature('Advanced batch operations'),
            _buildPremiumFeature('Priority processing queue'),
            _buildPremiumFeature('Batch scheduling'),
            _buildPremiumFeature('Cloud storage integration'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Premium features unlocked! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('Upgrade \$9.99/month'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class BatchOperation {
  final String name;
  final IconData icon;
  final String description;

  BatchOperation(this.name, this.icon, this.description);
}

class BatchItem {
  final String name;
  final String type;
  final double size;
  BatchStatus status;

  BatchItem(this.name, this.type, this.size, this.status);
}

enum BatchStatus {
  pending,
  processing,
  completed,
  failed,
}
