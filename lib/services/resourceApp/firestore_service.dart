import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resourceApp/request_model.dart';
import '../../models/resourceApp/task_model.dart';

class FirestoreServiceResource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _requestsCollection =>
      _firestore.collection('requests_resource');

  CollectionReference get _tasksCollection =>
      _firestore.collection('tasks_resource');

  // Membuat laporan resource baru
  Future<void> createRequest(RequestModel request) async {
    try {
      // Log untuk debugging gambar
      if (request.imageUrl != null && request.imageUrl!.isNotEmpty) {
        print('Creating resource request with image URL: ${request.imageUrl}');
      } else {
        print('Creating resource request without image URL');
      }

      final docRef = await _requestsCollection.add(request.toMap());
      print('Resource request created with ID: ${docRef.id}');

      // Verifikasi apakah imageUrl tersimpan dengan benar
      final savedRequest = await docRef.get();
      final savedData = savedRequest.data() as Map<String, dynamic>?;
      if (savedData != null && savedData['imageUrl'] != null) {
        print('Verified image URL saved: ${savedData['imageUrl']}');
      } else if (request.imageUrl != null && request.imageUrl!.isNotEmpty) {
        print(
            'Warning: Image URL may not have been saved correctly for request ${docRef.id}');
      }
    } catch (e) {
      print('Error creating resource request: $e');
      rethrow;
    }
  }

  // Mendapatkan semua laporan resource
  Stream<List<RequestModel>> getRequests() {
    return _requestsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final request = RequestModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (request.hasValidImage()) {
          print(
              'Retrieved request ${request.id} with image URL: ${request.imageUrl}');
        }
        return request;
      }).toList();
    });
  }

  // Mendapatkan laporan resource untuk employee tertentu
  Stream<List<RequestModel>> getRequestsByEmployee(String employeeId) {
    return _requestsCollection
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final request = RequestModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (request.hasValidImage()) {
          print(
              'Retrieved employee request ${request.id} with image URL: ${request.imageUrl}');
        }
        return request;
      }).toList();
    });
  }

  // Memperbarui status laporan resource
  Future<void> updateRequeststatus(String requestId, String status,
      {String? completionReason}) async {
    try {
      Map<String, dynamic> data = {'status': status};
      if (completionReason != null) {
        data['completionReason'] = completionReason;
      }
      await _requestsCollection.doc(requestId).update(data);
    } catch (e) {
      print('Error updating resource request status: $e');
      rethrow;
    }
  }

  // Menugaskan teknisi ke laporan resource dan membuat task baru
  Future<void> assignTechnician(
      RequestModel request, String technicianId, String technicianName) async {
    try {
      final batch = _firestore.batch();

      if (request.status == 'inProgress' &&
          request.assignedTechnicianId != null) {
        final oldTaskQuery = await _tasksCollection
            .where('requestId', isEqualTo: request.id)
            .limit(1)
            .get();

        if (oldTaskQuery.docs.isNotEmpty) {
          final oldTaskDoc = oldTaskQuery.docs.first;
          batch.delete(oldTaskDoc.reference);
          print('Task lama ${oldTaskDoc.id} akan dihapus.');
        }
      }

      batch.update(_requestsCollection.doc(request.id), {
        'status': 'inProgress',
        'assignedTechnicianId': technicianId,
        'technicianName': technicianName,
      });

      final taskRef = _tasksCollection.doc();
      final task = TaskModel(
        id: taskRef.id,
        requestId: request.id,
        assignedTo: technicianId,
        technicianName: technicianName,
        requesterName: request.employeeName,
        description: request.description,
        status: 'inProgress',
        assignedAt: DateTime.now(),
        timeRequired: request.timeRequired,
        request: request.request,
        imageUrl: request.imageUrl,
      );
      batch.set(taskRef, task.toMap());

      await batch.commit();
      print(
          'Teknisi $technicianName berhasil ditugaskan untuk request ${request.id}');

      if (request.hasValidImage()) {
        print('Task dibuat dengan image URL dari request: ${request.imageUrl}');
      }
    } catch (e) {
      print('Error saat menugaskan teknisi untuk resource: $e');
      rethrow;
    }
  }

  // Menandai laporan resource sebagai selesai
  Future<void> completeRequest(String requestId, String reason,
      {String? technicianId, String? technicianName}) async {
    try {
      final batch = _firestore.batch();

      // Update laporan
      batch.update(_requestsCollection.doc(requestId), {
        'status': 'completed',
        'completionReason': reason,
        'completionDate': FieldValue.serverTimestamp(),
      });

      // Jika diselesaikan langsung oleh officer, buat task baru yang sudah selesai
      if (technicianId != null && technicianName != null) {
        final requestDoc = await _requestsCollection.doc(requestId).get();
        final request = RequestModel.fromFirestore(requestDoc);

        final taskRef = _tasksCollection.doc();
        final task = TaskModel(
          id: taskRef.id,
          requestId: requestId,
          assignedTo: technicianId,
          technicianName: technicianName,
          requesterName: request.employeeName,
          description: request.description,
          status: 'completed',
          assignedAt: request.createdAt,
          completedAt: DateTime.now(),
          completionNote: reason,
          timeRequired: request.timeRequired,
          request: request.request,
          imageUrl: request.imageUrl,
        );
        batch.set(taskRef, task.toMap());

        // Log untuk image URL
        if (request.hasValidImage()) {
          print(
              'Direct completion task created with image URL: ${request.imageUrl}');
        }
      } else {
        // ... (sisa logika tidak berubah)
        final taskQuery = await _tasksCollection
            .where('requestId', isEqualTo: requestId)
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
      await batch.commit();
      print('Resource request $requestId marked as completed');
    } catch (e) {
      print('Error completing resource request: $e');
      rethrow;
    }
  }

  // Mendapatkan tasks untuk teknisi tertentu
  Stream<List<TaskModel>> getTasksByTechnician(String technicianId) {
    return _tasksCollection
        .where('assignedTo', isEqualTo: technicianId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final task = TaskModel.fromFirestore(doc);
        // Log untuk debugging gambar
        if (task.imageUrl != null && task.imageUrl!.isNotEmpty) {
          print('Retrieved task ${task.id} with image URL: ${task.imageUrl}');
        }
        return task;
      }).toList();
    });
  }

  // Memperbarui status task
  Future<void> updateTaskStatus(String taskId, String status,
      {String? completionNote}) async {
    try {
      Map<String, dynamic> data = {'status': status};
      if (status == 'completed') {
        data['completedAt'] = FieldValue.serverTimestamp();
        if (completionNote != null) {
          data['completionNote'] = completionNote;
        }
      }
      await _tasksCollection.doc(taskId).update(data);

      // Jika task selesai, update juga laporannya
      if (status == 'completed') {
        final taskDoc = await _tasksCollection.doc(taskId).get();
        final task = TaskModel.fromFirestore(taskDoc);
        await _requestsCollection.doc(task.requestId).update({
          'status': 'completed',
          'completionReason': completionNote ?? 'Completed by technician',
          'completionDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating resource task status: $e');
      rethrow;
    }
  }
}
