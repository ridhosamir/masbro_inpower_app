import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masbro_inpower_app/services/storage_service.dart';
import 'package:provider/provider.dart';
import '../../../models/maintenanceApp/task_model.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../widgets/custom_button.dart';

class CompleteTaskScreen extends StatefulWidget {
  final TaskModel task;

  const CompleteTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  _CompleteTaskScreenState createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _afterImageFile;
  XFile? _afterImageXFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _afterImageXFile = pickedFile;
          if (!kIsWeb) {
            _afterImageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_afterImageXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload an after repair image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload after image
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      String imageUrl;

      // Handle upload differently based on platform
      if (kIsWeb) {
        // Web upload
        final bytes = await _afterImageXFile!.readAsBytes();
        imageUrl = await storageService.uploadWebFile(
          bytes,
          'after_images/${widget.task.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else {
        // Mobile upload
        imageUrl = await storageService.uploadFile(
          _afterImageFile!,
          'after_images/${widget.task.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Complete the task and report
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      await firestore.completeTaskWithImage(
        taskId: widget.task.id,
        reportId: widget.task.reportId,
        completionNote: _descriptionController.text,
        afterImageUrl: imageUrl,
      );

      Navigator.of(context).pop(true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing task: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Task'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Completion Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Task Info Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Room', widget.task.roomName),
                      if (widget.task.itemName.isNotEmpty)
                        _buildInfoRow('Item', widget.task.itemName),
                      _buildInfoRow(
                        'Description',
                        widget.task.description,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Before Image
              if (widget.task.imageUrl != null &&
                  widget.task.imageUrl!.isNotEmpty) ...[
                Text(
                  'Before Repair Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.task.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    color: Colors.grey[400], size: 48),
                                SizedBox(height: 8),
                                Text('Failed to load image'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Completion Description
              Text(
                'Work Description *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Describe the work you completed...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the completed work';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // After Image
              Text(
                'After Repair Photo *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _afterImageXFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  _afterImageXFile!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  _afterImageFile!,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '* Required to submit completion',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 30),

              // Submit Button
              CustomButton(
                text: 'Submit Completion',
                onPressed: _isLoading ? null : () => _submitCompletion(),
                isLoading: _isLoading,
                backgroundColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
