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

      // Update laporan
      batch.update(_requestsCollection.doc(request.id), {
        'status': 'inProgress',
        'assignedTechnicianId': technicianId,
        'technicianName': technicianName,
      });

      // Buat task baru
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
      );
      batch.set(taskRef, task.toMap());

      await batch.commit();
    } catch (e) {
      print('Error assigning technician for resource: $e');
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
        );
        batch.set(taskRef, task.toMap());
      } else {
        // Jika task sudah ada, update statusnya
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
          'completionDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating resource task status: $e');
      rethrow;
    }
  }
}
