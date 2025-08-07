import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/maintenanceApp/report_model.dart';
import '../../models/maintenanceApp/task_model.dart';
import '../../models/maintenanceApp/building_model.dart';
import '../../models/maintenanceApp/room_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');
  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _buildingsCollection =>
      _firestore.collection('buildings');
  CollectionReference get _roomsCollection => _firestore.collection('rooms');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _ratingsCollection =>
      _firestore.collection('technician_ratings');
  CollectionReference get _reviewsCollection =>
      _firestore.collection('technician_reviews');

  // BUILDING MANAGEMENT
  // Cek apakah nama gedung sudah ada (tidak case sensitive)
  Future<bool> buildingNameExists(String name,
      {String? excludeBuildingId}) async {
    try {
      // Konversi nama ke lowercase untuk perbandingan case-insensitive
      final lowercaseName = name.toLowerCase();

      // Ambil semua dokumen gedung
      final snapshot = await _buildingsCollection.get();

      // Filter hasil secara manual untuk pencocokan case-insensitive
      final matches = snapshot.docs.where((doc) {
        // Lewati dokumen yang sedang diupdate
        if (excludeBuildingId != null && doc.id == excludeBuildingId) {
          return false;
        }

        final data = doc.data() as Map<String, dynamic>;
        final buildingName = data['name'] as String? ?? '';
        return buildingName.toLowerCase() == lowercaseName;
      }).toList();

      return matches.isNotEmpty;
    } catch (e) {
      print('Error checking building name: $e');
      rethrow;
    }
  }

  // Create a new building
  Future<void> createBuilding(BuildingModel building) async {
    try {
      // Cek apakah nama gedung sudah ada
      final nameExists = await buildingNameExists(building.name);
      if (nameExists) {
        throw Exception(
            'Building with the name "${building.name}" already exists.');
      }

      final docRef = await _buildingsCollection.add(building.toMap());
      print('Building created with ID: ${docRef.id}');
    } catch (e) {
      print('Error creating building: $e');
      throw e;
    }
  }

  // Get all buildings
  Stream<List<BuildingModel>> getBuildings() {
    return _buildingsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BuildingModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get building by ID
  Future<BuildingModel?> getBuildingById(String buildingId) async {
    try {
      final doc = await _buildingsCollection.doc(buildingId).get();
      if (doc.exists) {
        return BuildingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting building by ID: $e');
      throw e;
    }
  }

  // Update building
  Future<void> updateBuilding(BuildingModel building) async {
    try {
      // Cek apakah ada gedung lain dengan nama yang sama
      final nameExists = await buildingNameExists(building.name,
          excludeBuildingId: building.id);
      if (nameExists) {
        throw Exception(
            'Another building with the name "${building.name}" already exists.');
      }

      // Start a batch to update building and all related rooms atomically
      final batch = _firestore.batch();

      // Update the building document
      batch.update(_buildingsCollection.doc(building.id), building.toMap());

      // Find all rooms that belong to this building
      final roomsQuery = await _roomsCollection
          .where('buildingId', isEqualTo: building.id)
          .get();

      // Update each room's buildingName field
      for (var roomDoc in roomsQuery.docs) {
        batch.update(roomDoc.reference, {'buildingName': building.name});
      }

      // Commit the batch
      await batch.commit();

      print(
          'Building ${building.id} updated and ${roomsQuery.docs.length} rooms updated with new building name');
    } catch (e) {
      print('Error updating building: $e');
      throw e;
    }
  }

  // Delete building
  Future<void> deleteBuilding(String buildingId) async {
    try {
      // Check if there are rooms in this building
      final roomsQuery = await _roomsCollection
          .where('buildingId', isEqualTo: buildingId)
          .get();

      if (roomsQuery.docs.isNotEmpty) {
        throw Exception(
            'Cannot delete building with existing rooms. Delete all rooms first.');
      }

      await _buildingsCollection.doc(buildingId).delete();
      print('Building $buildingId deleted');
    } catch (e) {
      print('Error deleting building: $e');
      throw e;
    }
  }

  // ROOM MANAGEMENT
  // Cek apakah nama ruangan sudah ada dalam suatu gedung (tidak case sensitive)
  Future<bool> roomNameExistsInBuilding(String buildingId, String roomName,
      {String? excludeRoomId}) async {
    try {
      // Konversi nama ke lowercase untuk perbandingan case-insensitive
      final lowercaseRoomName = roomName.toLowerCase();

      // Ambil semua ruangan dalam gedung ini
      final snapshot = await _roomsCollection
          .where('buildingId', isEqualTo: buildingId)
          .get();

      // Filter hasil secara manual untuk pencocokan case-insensitive
      final matches = snapshot.docs.where((doc) {
        // Lewati dokumen yang sedang diupdate
        if (excludeRoomId != null && doc.id == excludeRoomId) {
          return false;
        }

        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        return name.toLowerCase() == lowercaseRoomName;
      }).toList();

      return matches.isNotEmpty;
    } catch (e) {
      print('Error checking room name: $e');
      rethrow;
    }
  }

  // Create a new room
  Future<void> createRoom(RoomModel room) async {
    try {
      // Cek apakah nama ruangan sudah ada dalam gedung yang sama
      final nameExists =
          await roomNameExistsInBuilding(room.buildingId, room.name);
      if (nameExists) {
        throw Exception(
            'Room with the name "${room.name}" already exists in this building.');
      }

      final docRef = await _roomsCollection.add(room.toMap());
      print('Room created with ID: ${docRef.id}');
    } catch (e) {
      print('Error creating room: $e');
      throw e;
    }
  }

  // Get all rooms
  Stream<List<RoomModel>> getRooms() {
    return _roomsCollection
        .orderBy('buildingName')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    });
  }

  // Get rooms by building ID
  Stream<List<RoomModel>> getRoomsByBuilding(String buildingId) {
    // Validasi input
    if (buildingId.isEmpty) return Stream.value([]);

    try {
      return _roomsCollection
          .where('buildingId', isEqualTo: buildingId)
          .orderBy('name', descending: false) // Explicit order
          .snapshots()
          .handleError((error) {
        debugPrint('Firestore Error: $error');
        throw error;
      }).map((snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error in query: $e');
      rethrow;
    }
  }

  // Get room by ID
  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      final doc = await _roomsCollection.doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting room by ID: $e');
      throw e;
    }
  }

  // Update room
  Future<void> updateRoom(RoomModel room) async {
    try {
      // Cek apakah ada ruangan lain dengan nama yang sama dalam gedung yang sama
      final nameExists = await roomNameExistsInBuilding(
          room.buildingId, room.name,
          excludeRoomId: room.id);

      if (nameExists) {
        throw Exception(
            'Another room with the name "${room.name}" already exists in this building.');
      }

      await _roomsCollection.doc(room.id).update(room.toMap());
      print('Room ${room.id} updated');
    } catch (e) {
      print('Error updating room: $e');
      throw e;
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      // Check if there are reports using this room
      final reportsQuery =
          await _reportsCollection.where('roomId', isEqualTo: roomId).get();

      if (reportsQuery.docs.isNotEmpty) {
        throw Exception('Cannot delete room that is used in reports.');
      }

      await _roomsCollection.doc(roomId).delete();
      print('Room $roomId deleted');
    } catch (e) {
      print('Error deleting room: $e');
      throw e;
    }
  }

  // REPORT MANAGEMENT
  // Create a new report
  Future<void> createReport(ReportModel report) async {
    try {
      // Log for debugging image
      if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
        print('Creating report with image URL: ${report.imageUrl}');
      } else {
        print('Creating report without image URL');
      }

      // Create report
      final docRef = await _reportsCollection.add(report.toMap());
      print('Report created with ID: ${docRef.id}');

      // Verify image URL saved correctly
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
        // Log for debugging image
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
        // Log for debugging image
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

      // Add completion reason if provided
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
        'status': 'inProgress',
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
        imageUrl: report.imageUrl, // Make sure to include the image URL
      );

      batch.set(taskRef, task.toMap());

      // Commit the batch
      await batch.commit();
      print('Technician $technicianName assigned to report ${report.id}');

      // Log for image URL
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
        'status': 'completed',
        'completionReason': reason,
        'completionDate': FieldValue.serverTimestamp(),
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
          imageUrl: report.imageUrl, // Make sure to include the image URL
        );

        batch.set(taskRef, task.toMap());

        // Log for image URL
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
        // Log for debugging image
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
          'completionDate': FieldValue.serverTimestamp(),
        });

        print('Task $taskId and report ${task.reportId} marked as completed');
      }
    } catch (e) {
      print('Error updating task status: $e');
      throw e;
    }
  }

  // Function to verify if image URL is accessible
  Future<bool> verifyImageUrl(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        return false;
      }

      // If URL starts with gs:// (Firebase Storage URI)
      if (imageUrl.startsWith('gs://')) {
        try {
          // Try to extract path and get reference
          final path = imageUrl.replaceFirst('gs://', '');
          final segments = path.split('/');
          if (segments.length >= 2) {
            final bucket = segments[0];
            final objectPath = segments.sublist(1).join('/');
            // Firebase Storage doesn't have an API to directly verify URL
            // So we assume it's correct if the URL format is valid
            print('Storage URL appears valid: gs://$bucket/$objectPath');
            return true;
          }
          return false;
        } catch (e) {
          print('Invalid gs:// URL format: $e');
          return false;
        }
      }

      // If URL is an https URL
      if (imageUrl.startsWith('http')) {
        print('HTTP URL detected: $imageUrl');
        // In a real application, you could do an HTTP HEAD request
        // to verify the URL is accessible, but this is more complex
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying image URL: $e');
      return false;
    }
  }

  // Function to get report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();
      if (doc.exists) {
        final report = ReportModel.fromFirestore(doc);
        // Log for debugging image
        if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
          print(
              'Retrieved report $reportId with image URL: ${report.imageUrl}');
          // Verify image URL
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

  /// METODE RATING YANG DIPERBARUI ///

  /// Menambahkan rating dan review untuk teknisi
  Future<void> rateTechnician(
      String reportId, double rating, String technicianId,
      {String? review}) async {
    try {
      print(
          'Starting rating process for report $reportId, technician $technicianId with rating $rating');

      // 1. Update rating and review in the report document first
      try {
        Map<String, dynamic> updateData = {'technicianRating': rating};

        // Add review if provided
        if (review != null && review.isNotEmpty) {
          updateData['technicianReview'] = review;
        }

        await _reportsCollection.doc(reportId).update(updateData);
        print('Report rating and review updated successfully');
      } catch (e) {
        print('Error updating report rating and review: $e');
        throw Exception('Failed to update report rating and review: $e');
      }

      // 2. Save rating to separate collection
      try {
        Map<String, dynamic> ratingData = {
          'technicianId': technicianId,
          'reportId': reportId,
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Add review if provided
        if (review != null && review.isNotEmpty) {
          ratingData['review'] = review;
        }

        await _ratingsCollection.add(ratingData);
        print('Rating saved to separate collection');

        // Also save to reviews collection if review is provided
        if (review != null && review.isNotEmpty) {
          await _reviewsCollection.add({
            'technicianId': technicianId,
            'reportId': reportId,
            'review': review,
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('Review saved to separate collection');
        }
      } catch (e) {
        print('Error saving rating/review to separate collection: $e');
        // Continue execution even if this fails
      }

      // 3. Try to update user document (but don't fail the entire operation if this fails)
      try {
        // Get technician ratings from separate collection
        final ratingData =
            await _calculateAverageRatingFromCollection(technicianId);

        // Try to update the technician document with new rating data
        await _usersCollection.doc(technicianId).update({
          'totalRatings': ratingData['totalRatings'],
          'averageRating': ratingData['averageRating'],
        });
        print('Technician rating updated successfully in user document');
      } catch (e) {
        print('Warning: Could not update technician document directly: $e');
        print(
            'Rating was saved to separate collection and can be accessed from there');
      }

      print('Rating process completed');
    } catch (e) {
      print('Error in rating process: $e');
      throw e;
    }
  }

  /// Calculate average rating from separate collection
  Future<Map<String, dynamic>> _calculateAverageRatingFromCollection(
      String technicianId) async {
    try {
      // Get all ratings for this technician
      final snapshot = await _ratingsCollection
          .where('technicianId', isEqualTo: technicianId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalRatings': 0,
          'averageRating': 0.0,
        };
      }

      double totalRating = 0;
      final totalRatings = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = data['rating'] is int
            ? (data['rating'] as int).toDouble()
            : data['rating'] as double;
        totalRating += rating;
      }

      final averageRating = totalRating / totalRatings;

      print(
          'Calculated rating for technician $technicianId: $averageRating from $totalRatings ratings');

      return {
        'totalRatings': totalRatings,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error calculating average rating: $e');
      return {
        'totalRatings': 0,
        'averageRating': 0.0,
      };
    }
  }

  /// Get technician rating data - Use this method to get rating info for display
  Future<Map<String, dynamic>> getTechnicianRatingData(
      String technicianId) async {
    try {
      // First try to get rating from user document
      final userDoc = await _usersCollection.doc(technicianId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData['averageRating'] != null &&
            userData['totalRatings'] != null) {
          // Convert to proper types
          double averageRating = userData['averageRating'] is int
              ? (userData['averageRating'] as int).toDouble()
              : userData['averageRating'] as double;

          int totalRatings = userData['totalRatings'] as int;

          return {
            'averageRating': averageRating,
            'totalRatings': totalRatings,
            'source': 'user_document',
          };
        }
      }

      // If user document doesn't have rating data, calculate from ratings collection
      final ratingData =
          await _calculateAverageRatingFromCollection(technicianId);
      ratingData['source'] = 'ratings_collection';

      return ratingData;
    } catch (e) {
      print('Error getting technician rating data: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get technician reviews
  Future<List<Map<String, dynamic>>> getTechnicianReviews(
      String technicianId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('technicianId', isEqualTo: technicianId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'review': data['review'] as String,
          'rating': data['rating'] is int
              ? (data['rating'] as int).toDouble()
              : data['rating'] as double,
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'reportId': data['reportId'] as String,
        };
      }).toList();
    } catch (e) {
      print('Error getting technician reviews: $e');
      return [];
    }
  }

  /// Get report with updated rating (memastikan data rating terbaru)
  Future<ReportModel?> getReportWithRating(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();
      if (doc.exists) {
        final report = ReportModel.fromFirestore(doc);
        print(
            'Retrieved report $reportId with rating: ${report.technicianRating}');
        return report;
      }
      return null;
    } catch (e) {
      print('Error getting report with rating: $e');
      throw e;
    }
  }

  // Complete task with after image
  Future<void> completeTaskWithImage({
    required String taskId,
    required String reportId,
    required String completionNote,
    required String afterImageUrl,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // Update task
      batch.update(_tasksCollection.doc(taskId), {
        'status': 'completed',
        'completedAt': now,
        'completionNote': completionNote,
        'afterImageUrl': afterImageUrl,
      });

      // Update report
      batch.update(_reportsCollection.doc(reportId), {
        'status': 'completed',
        'completionDate': now,
        'completionReason': completionNote,
        'afterImageUrl': afterImageUrl,
      });

      await batch.commit();
      print('Task $taskId and report $reportId completed with after image');
    } catch (e) {
      print('Error completing task with image: $e');
      throw e;
    }
  }

  // Add user review to a task
  Future<void> addUserReviewToTask(
      String taskId, double rating, String review) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'userRating': rating,
        'userReview': review,
      });

      // Get task info to update the report and technician stats
      final taskDoc = await _tasksCollection.doc(taskId).get();
      if (taskDoc.exists) {
        final task = TaskModel.fromFirestore(taskDoc);

        // Also update the report with this rating and review
        await rateTechnician(task.reportId, rating, task.assignedTo,
            review: review);
      }

      print('User review added to task $taskId');
    } catch (e) {
      print('Error adding user review to task: $e');
      throw e;
    }
  }
}
