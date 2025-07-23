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
      await _requestsCollection.add(request.toMap());
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
      return snapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    });
  }

  // Mendapatkan laporan resource untuk employee tertentu
  Stream<List<RequestModel>> getRequestsByEmployee(String employeeId) {
    return _requestsCollection
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
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
      final requestRef = _requestsCollection.doc(request.id);

      batch.update(requestRef, {
        'status': 'inProgress',
        'assignedTechnicianId': technicianId,
        'technicianName': technicianName,
      });

      final taskQuery = await _tasksCollection
          .where('requestId', isEqualTo: request.id)
          .limit(1)
          .get();

      if (taskQuery.docs.isNotEmpty) {
        final existingTaskRef = taskQuery.docs.first.reference;
        batch.update(existingTaskRef, {
          'assignedTo': technicianId,
          'technicianName': technicianName,
          'assignedAt': Timestamp.now(),
        });
      } else {
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
        );
        batch.set(taskRef, task.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Error assigning/re-assigning technician for resource: $e');
      rethrow;
    }
  }

  // Menandai laporan resource sebagai selesai
  Future<void> completeRequest(RequestModel request, String reason,
      {required String officerId, required String officerName}) async {
    try {
      final batch = _firestore.batch();
      final requestRef = _requestsCollection.doc(request.id);

      // 1. Update dokumen request utama
      // Sesuai permintaan: assignedTechnicianId diisi ID officer, technicianName dikosongkan
      batch.update(requestRef, {
        'status': 'completed',
        'completionReason': reason,
        'assignedTechnicianId': officerId,
        'technicianName': null, // Mengosongkan nama teknisi
      });

      // 2. Cari task yang mungkin sudah ada untuk request ini
      final taskQuery = await _tasksCollection
          .where('requestId', isEqualTo: request.id)
          .limit(1)
          .get();

      if (taskQuery.docs.isNotEmpty) {
        // JIKA TASK ADA: Update task tersebut untuk mencatat bahwa officer yang menyelesaikan
        final taskRef = taskQuery.docs.first.reference;
        batch.update(taskRef, {
          'status': 'completed',
          'completedAt': Timestamp.now(),
          'completionNote': reason,
          // Tetap catat di task siapa yang menyelesaikan (yaitu officer)
          'assignedTo': officerId,
          'technicianName': officerName,
        });
      } else {
        // JIKA TASK TIDAK ADA (misal dari status 'open'): Buat task baru yang sudah selesai atas nama officer
        final taskRef = _tasksCollection.doc();
        final task = TaskModel(
          id: taskRef.id,
          requestId: request.id,
          assignedTo: officerId,
          technicianName: officerName,
          requesterName: request.employeeName,
          description: request.description,
          status: 'completed',
          assignedAt: request.createdAt,
          completedAt: DateTime.now(),
          completionNote: reason,
          timeRequired: request.timeRequired,
        );
        batch.set(taskRef, task.toMap());
      }

      await batch.commit();
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
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
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
        });
      }
    } catch (e) {
      print('Error updating resource task status: $e');
      rethrow;
    }
  }
}
