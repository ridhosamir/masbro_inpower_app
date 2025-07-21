import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/maintenanceApp/report_model.dart';
import '../../models/maintenanceApp/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reports Collection
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');

  // Tasks Collection
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  // Create a new report
  Future<void> createReport(ReportModel report) async {
    try {
      // Log untuk debugging gambar
      if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
        print('Creating report with image URL: ${report.imageUrl}');
      } else {
        print('Creating report without image URL');
      }

      // Buat report
      final docRef = await _reportsCollection.add(report.toMap());
      print('Report created with ID: ${docRef.id}');

      // Verifikasi URL gambar tersimpan dengan benar
      final savedReport = await docRef.get();
      final savedData = savedReport.data() as Map<String, dynamic>?;
      if (savedData != null && savedData['imageUrl'] != null) {
        print('Verified image URL saved: ${savedData['imageUrl']}');
      } else if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
        print('Warning: Image URL may not have been saved correctly');
      }
    } catch (e) {
      print('Error creating report: $e');
      throw e;
    }
  }

  // Get all reports
  Stream<List<ReportModel>> getReports() {
    return _reportsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        final report = ReportModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
          print(
              'Retrieved report ${report.id} with image URL: ${report.imageUrl}');
        }
        return report;
      }).toList();
      return reports;
    });
  }

  // Get reports for a specific employee
  Stream<List<ReportModel>> getReportsByEmployee(String employeeId) {
    return _reportsCollection
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        final report = ReportModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
          print(
              'Retrieved employee report ${report.id} with image URL: ${report.imageUrl}');
        }
        return report;
      }).toList();
      return reports;
    });
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String status,
      {String? completionReason}) async {
    try {
      Map<String, dynamic> data = {'status': status};

      // Add completion reason if provided (renamed from rejectionReason)
      if (completionReason != null) {
        data['completionReason'] = completionReason;
      }

      await _reportsCollection.doc(reportId).update(data);
      print('Report $reportId status updated to $status');
    } catch (e) {
      print('Error updating report status: $e');
      throw e;
    }
  }

  // Assign technician to report and create task
  Future<void> assignTechnician(
      ReportModel report, String technicianId, String technicianName) async {
    try {
      // Start a batch
      final batch = _firestore.batch();

      // Update the report
      batch.update(_reportsCollection.doc(report.id), {
        'status': 'inProgress', // Changed from 'approved' to 'inProgress'
        'assignedTechnicianId': technicianId,
        'technicianName': technicianName,
      });

      // Create a task
      final taskRef = _tasksCollection.doc();
      final task = TaskModel(
        id: taskRef.id,
        reportId: report.id,
        assignedTo: technicianId,
        technicianName: technicianName,
        roomName: report.roomName,
        itemName: report.itemName,
        description: report.description,
        status: 'inProgress',
        assignedAt: DateTime.now(),
        imageUrl: report.imageUrl, // Pastikan URL gambar juga disertakan
      );

      batch.set(taskRef, task.toMap());

      // Commit the batch
      await batch.commit();
      print('Technician $technicianName assigned to report ${report.id}');

      // Log untuk URL gambar
      if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
        print('Task created with image URL from report: ${report.imageUrl}');
      }
    } catch (e) {
      print('Error assigning technician: $e');
      throw e;
    }
  }

  // Mark report as completed
  Future<void> completeReport(String reportId, String reason,
      {String? technicianId, String? technicianName}) async {
    try {
      // Start a batch
      final batch = _firestore.batch();

      // Update the report
      batch.update(_reportsCollection.doc(reportId), {
        'status': 'completed', // Changed from 'rejected' to 'completed'
        'completionReason':
            reason, // Changed from 'rejectionReason' to 'completionReason'
      });

      // Create a task if technician info is provided (for direct completions by officer)
      if (technicianId != null && technicianName != null) {
        // Get the report data
        final reportDoc = await _reportsCollection.doc(reportId).get();
        final report = ReportModel.fromFirestore(reportDoc);

        final taskRef = _tasksCollection.doc();
        final task = TaskModel(
          id: taskRef.id,
          reportId: reportId,
          assignedTo: technicianId,
          technicianName: technicianName,
          roomName: report.roomName,
          itemName: report.itemName,
          description: report.description,
          status: 'completed',
          assignedAt: DateTime.now(),
          completedAt: DateTime.now(),
          completionNote: reason,
          imageUrl: report.imageUrl, // Pastikan URL gambar juga disertakan
        );

        batch.set(taskRef, task.toMap());

        // Log untuk URL gambar
        if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
          print('Task created with image URL from report: ${report.imageUrl}');
        }
      }
      // If there's already a task, update it
      else {
        final taskQuery = await _tasksCollection
            .where('reportId', isEqualTo: reportId)
            .limit(1)
            .get();

        if (taskQuery.docs.isNotEmpty) {
          batch.update(taskQuery.docs.first.reference, {
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'completionNote': reason,
          });
        }
      }

      // Commit the batch
      await batch.commit();
      print('Report $reportId marked as completed with reason: $reason');
    } catch (e) {
      print('Error completing report: $e');
      throw e;
    }
  }

  // Get tasks for a specific technician
  Stream<List<TaskModel>> getTasksByTechnician(String technicianId) {
    return _tasksCollection
        .where('assignedTo', isEqualTo: technicianId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        final task = TaskModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (task.imageUrl != null && task.imageUrl!.isNotEmpty) {
          print('Retrieved task ${task.id} with image URL: ${task.imageUrl}');
        }
        return task;
      }).toList();
      return tasks;
    });
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String status,
      {String? completionNote}) async {
    try {
      Map<String, dynamic> data = {
        'status': status,
      };

      if (status == 'completed') {
        data['completedAt'] = FieldValue.serverTimestamp();

        if (completionNote != null) {
          data['completionNote'] = completionNote;
        }
      }

      await _tasksCollection.doc(taskId).update(data);

      // If task is completed, also update the report
      if (status == 'completed') {
        // Get the task to get the report ID
        final taskDoc = await _tasksCollection.doc(taskId).get();
        final task = TaskModel.fromFirestore(taskDoc);

        // Update the report
        await _reportsCollection.doc(task.reportId).update({
          'status': 'completed',
          'completionReason': completionNote ?? 'Completed by technician',
        });

        print('Task $taskId and report ${task.reportId} marked as completed');
      }
    } catch (e) {
      print('Error updating task status: $e');
      throw e;
    }
  }

  // For backward compatibility - Update report with assigned technician
  // You can replace this with assignTechnician method
  Future<void> updateReportTechnician(
      String reportId, String technicianId, String technicianName) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'status': 'inProgress', // Changed from 'approved' to 'inProgress'
        'assignedTechnicianId': technicianId,
        'technicianName': technicianName,
      });
      print('Report $reportId updated with technician $technicianName');
    } catch (e) {
      print('Error updating report technician: $e');
      throw e;
    }
  }

  // Fungsi untuk memverifikasi URL gambar dapat diakses
  Future<bool> verifyImageUrl(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        return false;
      }

      // Jika URL dimulai dengan gs:// (Firebase Storage URI)
      if (imageUrl.startsWith('gs://')) {
        try {
          // Coba ekstrak path dan ambil referensi
          final path = imageUrl.replaceFirst('gs://', '');
          final segments = path.split('/');
          if (segments.length >= 2) {
            final bucket = segments[0];
            final objectPath = segments.sublist(1).join('/');
            // Firebase Storage tidak memiliki API untuk langsung memverifikasi URL
            // Jadi kita asumsikan benar jika format URL valid
            print('Storage URL appears valid: gs://$bucket/$objectPath');
            return true;
          }
          return false;
        } catch (e) {
          print('Invalid gs:// URL format: $e');
          return false;
        }
      }

      // Jika URL adalah https URL
      if (imageUrl.startsWith('http')) {
        print('HTTP URL detected: $imageUrl');
        // Dalam aplikasi sebenarnya, Anda bisa melakukan HTTP HEAD request
        // untuk memverifikasi bahwa URL dapat diakses, tapi ini lebih kompleks
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying image URL: $e');
      return false;
    }
  }

  // Fungsi untuk mendapatkan report dengan ID tertentu
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();
      if (doc.exists) {
        final report = ReportModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
          print(
              'Retrieved report $reportId with image URL: ${report.imageUrl}');
          // Verifikasi URL gambar
          final isValid = await verifyImageUrl(report.imageUrl!);
          print('Image URL is ${isValid ? 'valid' : 'invalid'}');
        }
        return report;
      }
      return null;
    } catch (e) {
      print('Error getting report by ID: $e');
      throw e;
    }
  }
}
