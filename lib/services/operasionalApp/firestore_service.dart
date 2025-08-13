import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/operasionalApp/ride_request_model.dart';
import '../../models/operasionalApp/vehicle_model.dart';
import '../../models/operasionalApp/driver_model.dart';

class OperasionalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references (existing)
  final CollectionReference _rideRequestsCollection =
      FirebaseFirestore.instance.collection('ride_requests');
  final CollectionReference _vehiclesCollection =
      FirebaseFirestore.instance.collection('vehicles');
  final CollectionReference _driversCollection =
      FirebaseFirestore.instance.collection('drivers');

  // ✅ NEW: Rating collections yang akan membuat collection baru di Firestore
  CollectionReference get _driverRatingsCollection =>
      _firestore.collection('driver_ratings');
  CollectionReference get _driverReviewsCollection =>
      _firestore.collection('driver_reviews');
  CollectionReference get _vehicleRatingsCollection =>
      _firestore.collection('vehicle_ratings');
  CollectionReference get _vehicleReviewsCollection =>
      _firestore.collection('vehicle_reviews');

  // RIDE REQUESTS
  // Get all ride requests
  Stream<List<RideRequestModel>> getRideRequests() {
    return _rideRequestsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideRequestModel.fromSnapshot(doc))
          .toList();
    });
  }

  // Get ride requests by employee ID
  Stream<List<RideRequestModel>> getRideRequestsByEmployee(String employeeId) {
    return _rideRequestsCollection
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideRequestModel.fromSnapshot(doc))
          .toList();
    });
  }

  // Get ride requests by driver ID
  Stream<List<RideRequestModel>> getRideRequestsByDriver(String driverId) {
    return _rideRequestsCollection
        .where('driverId', isEqualTo: driverId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideRequestModel.fromSnapshot(doc))
          .toList();
    });
  }

  // Create a new ride request
  Future<void> createRideRequest(RideRequestModel request) async {
    await _rideRequestsCollection.add(request.toMap());
  }

  // Update a ride request
  Future<void> updateRideRequest(RideRequestModel request) async {
    await _rideRequestsCollection.doc(request.id).update(request.toMap());
  }

  // Assign driver and vehicle to a ride request
  Future<void> assignDriverAndVehicle(
    String requestId,
    String driverId,
    String driverName,
    String vehicleId,
    String vehicleName,
  ) async {
    // Use batch for atomic updates
    final batch = _firestore.batch();

    // Update ride request
    final requestRef = _rideRequestsCollection.doc(requestId);
    batch.update(requestRef, {
      'status': 'inProgress',
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'assignedAt': FieldValue.serverTimestamp(),
    });

    // Update vehicle availability
    final vehicleRef = _vehiclesCollection.doc(vehicleId);
    batch.update(vehicleRef, {
      'isAvailable': false,
      'status': 'in-use',
      'currentDriverId': driverId,
      'currentDriverName': driverName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update driver availability
    final driverRef = _driversCollection.doc(driverId);
    batch.update(driverRef, {
      'isAvailable': false,
      'currentVehicleId': vehicleId,
      'currentVehicleName': vehicleName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Execute all updates atomically
    await batch.commit();
  }

  // Complete a ride request
  Future<void> completeRideRequest(String requestId, String completionNote,
      {String? driverId, String? vehicleId}) async {
    // Use batch for atomic updates
    final batch = _firestore.batch();

    // Update request status
    final requestRef = _rideRequestsCollection.doc(requestId);
    batch.update(requestRef, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completionNote': completionNote,
    });

    // If driver ID is provided, update driver availability
    if (driverId != null) {
      final driverRef = _driversCollection.doc(driverId);
      batch.update(driverRef, {
        'isAvailable': true,
        'currentVehicleId': null,
        'currentVehicleName': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // If vehicle ID is provided, update vehicle availability
    if (vehicleId != null) {
      final vehicleRef = _vehiclesCollection.doc(vehicleId);
      batch.update(vehicleRef, {
        'isAvailable': true,
        'status': 'available',
        'currentDriverId': null,
        'currentDriverName': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Execute all updates atomically
    await batch.commit();
  }

  // ✅ NEW: RATING AND REVIEW SYSTEM WITH NEW COLLECTIONS

  /// Rate driver for a completed ride request - CREATES NEW COLLECTIONS
  Future<void> rateDriver(String requestId, double rating, String driverId,
      {String? review}) async {
    try {
      print(
          'Starting driver rating process for request $requestId, driver $driverId with rating $rating');

      // 1. Update rating and review in the ride request document first
      try {
        Map<String, dynamic> updateData = {'driverRating': rating};

        // Add review if provided
        if (review != null && review.isNotEmpty) {
          updateData['driverReview'] = review;
        }

        await _rideRequestsCollection.doc(requestId).update(updateData);
        print('Ride request driver rating and review updated successfully');
      } catch (e) {
        print('Error updating ride request driver rating and review: $e');
        throw Exception(
            'Failed to update ride request driver rating and review: $e');
      }

      // 2. ✅ Save rating to NEW separate collection 'driver_ratings'
      try {
        Map<String, dynamic> ratingData = {
          'driverId': driverId,
          'requestId': requestId,
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
          'ratedAt': DateTime.now().toIso8601String(),
        };

        // Add review if provided
        if (review != null && review.isNotEmpty) {
          ratingData['review'] = review;
        }

        // 🆕 This will CREATE NEW COLLECTION 'driver_ratings' if it doesn't exist
        await _driverRatingsCollection.add(ratingData);
        print('✅ NEW: Driver rating saved to NEW collection: driver_ratings');

        // 3. ✅ Also save to NEW reviews collection 'driver_reviews' if review is provided
        if (review != null && review.isNotEmpty) {
          await _driverReviewsCollection.add({
            'driverId': driverId,
            'requestId': requestId,
            'review': review,
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
            'reviewedAt': DateTime.now().toIso8601String(),
          });
          print('✅ NEW: Driver review saved to NEW collection: driver_reviews');
        }
      } catch (e) {
        print('Error saving driver rating/review to separate collection: $e');
        // Continue execution even if this fails
      }

      // 4. Try to update driver document (but don't fail the entire operation if this fails)
      try {
        // Get driver ratings from NEW separate collection
        final ratingData =
            await _calculateDriverAverageRatingFromCollection(driverId);

        // Try to update the driver document with new rating data
        await _driversCollection.doc(driverId).update({
          'totalRatings': ratingData['totalRatings'],
          'averageRating': ratingData['averageRating'],
          'lastRatedAt': FieldValue.serverTimestamp(),
        });
        print('Driver rating updated successfully in driver document');
      } catch (e) {
        print('Warning: Could not update driver document directly: $e');
        print(
            'Rating was saved to separate collection and can be accessed from there');
      }

      print('✅ Driver rating process completed - NEW collections created!');
    } catch (e) {
      print('Error in driver rating process: $e');
      throw e;
    }
  }

  /// Rate vehicle for a completed ride request - CREATES NEW COLLECTIONS
  Future<void> rateVehicle(String requestId, double rating, String vehicleId,
      {String? review}) async {
    try {
      print(
          'Starting vehicle rating process for request $requestId, vehicle $vehicleId with rating $rating');

      // 1. Update rating and review in the ride request document first
      try {
        Map<String, dynamic> updateData = {'vehicleRating': rating};

        // Add review if provided
        if (review != null && review.isNotEmpty) {
          updateData['vehicleReview'] = review;
        }

        await _rideRequestsCollection.doc(requestId).update(updateData);
        print('Ride request vehicle rating and review updated successfully');
      } catch (e) {
        print('Error updating ride request vehicle rating and review: $e');
        throw Exception(
            'Failed to update ride request vehicle rating and review: $e');
      }

      // 2. ✅ Save rating to NEW separate collection 'vehicle_ratings'
      try {
        Map<String, dynamic> ratingData = {
          'vehicleId': vehicleId,
          'requestId': requestId,
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
          'ratedAt': DateTime.now().toIso8601String(),
        };

        // Add review if provided
        if (review != null && review.isNotEmpty) {
          ratingData['review'] = review;
        }

        // 🆕 This will CREATE NEW COLLECTION 'vehicle_ratings' if it doesn't exist
        await _vehicleRatingsCollection.add(ratingData);
        print('✅ NEW: Vehicle rating saved to NEW collection: vehicle_ratings');

        // 3. ✅ Also save to NEW reviews collection 'vehicle_reviews' if review is provided
        if (review != null && review.isNotEmpty) {
          await _vehicleReviewsCollection.add({
            'vehicleId': vehicleId,
            'requestId': requestId,
            'review': review,
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
            'reviewedAt': DateTime.now().toIso8601String(),
          });
          print(
              '✅ NEW: Vehicle review saved to NEW collection: vehicle_reviews');
        }
      } catch (e) {
        print('Error saving vehicle rating/review to separate collection: $e');
        // Continue execution even if this fails
      }

      // 4. Try to update vehicle document (but don't fail the entire operation if this fails)
      try {
        // Get vehicle ratings from NEW separate collection
        final ratingData =
            await _calculateVehicleAverageRatingFromCollection(vehicleId);

        // Try to update the vehicle document with new rating data
        await _vehiclesCollection.doc(vehicleId).update({
          'totalRatings': ratingData['totalRatings'],
          'averageRating': ratingData['averageRating'],
          'lastRatedAt': FieldValue.serverTimestamp(),
        });
        print('Vehicle rating updated successfully in vehicle document');
      } catch (e) {
        print('Warning: Could not update vehicle document directly: $e');
        print(
            'Rating was saved to separate collection and can be accessed from there');
      }

      print('✅ Vehicle rating process completed - NEW collections created!');
    } catch (e) {
      print('Error in vehicle rating process: $e');
      throw e;
    }
  }

  /// Calculate average driver rating from NEW separate collection
  Future<Map<String, dynamic>> _calculateDriverAverageRatingFromCollection(
      String driverId) async {
    try {
      // Get all ratings for this driver from NEW collection
      final snapshot = await _driverRatingsCollection
          .where('driverId', isEqualTo: driverId)
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
          'Calculated rating for driver $driverId: $averageRating from $totalRatings ratings');

      return {
        'totalRatings': totalRatings,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error calculating driver average rating: $e');
      return {
        'totalRatings': 0,
        'averageRating': 0.0,
      };
    }
  }

  /// Calculate average vehicle rating from NEW separate collection
  Future<Map<String, dynamic>> _calculateVehicleAverageRatingFromCollection(
      String vehicleId) async {
    try {
      // Get all ratings for this vehicle from NEW collection
      final snapshot = await _vehicleRatingsCollection
          .where('vehicleId', isEqualTo: vehicleId)
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
          'Calculated rating for vehicle $vehicleId: $averageRating from $totalRatings ratings');

      return {
        'totalRatings': totalRatings,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error calculating vehicle average rating: $e');
      return {
        'totalRatings': 0,
        'averageRating': 0.0,
      };
    }
  }

  /// Get driver rating data
  Future<Map<String, dynamic>> getDriverRatingData(String driverId) async {
    try {
      // First try to get rating from driver document
      final driverDoc = await _driversCollection.doc(driverId).get();

      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;

        if (driverData['averageRating'] != null &&
            driverData['totalRatings'] != null) {
          // Convert to proper types
          double averageRating = driverData['averageRating'] is int
              ? (driverData['averageRating'] as int).toDouble()
              : driverData['averageRating'] as double;

          int totalRatings = driverData['totalRatings'] as int;

          return {
            'averageRating': averageRating,
            'totalRatings': totalRatings,
            'source': 'driver_document',
          };
        }
      }

      // If driver document doesn't have rating data, calculate from NEW ratings collection
      final ratingData =
          await _calculateDriverAverageRatingFromCollection(driverId);
      ratingData['source'] = 'ratings_collection';

      return ratingData;
    } catch (e) {
      print('Error getting driver rating data: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get vehicle rating data
  Future<Map<String, dynamic>> getVehicleRatingData(String vehicleId) async {
    try {
      // First try to get rating from vehicle document
      final vehicleDoc = await _vehiclesCollection.doc(vehicleId).get();

      if (vehicleDoc.exists) {
        final vehicleData = vehicleDoc.data() as Map<String, dynamic>;

        if (vehicleData['averageRating'] != null &&
            vehicleData['totalRatings'] != null) {
          // Convert to proper types
          double averageRating = vehicleData['averageRating'] is int
              ? (vehicleData['averageRating'] as int).toDouble()
              : vehicleData['averageRating'] as double;

          int totalRatings = vehicleData['totalRatings'] as int;

          return {
            'averageRating': averageRating,
            'totalRatings': totalRatings,
            'source': 'vehicle_document',
          };
        }
      }

      // If vehicle document doesn't have rating data, calculate from NEW ratings collection
      final ratingData =
          await _calculateVehicleAverageRatingFromCollection(vehicleId);
      ratingData['source'] = 'ratings_collection';

      return ratingData;
    } catch (e) {
      print('Error getting vehicle rating data: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'error': e.toString(),
      };
    }
  }

  /// ✅ NEW: Get driver reviews from NEW collection
  Future<List<Map<String, dynamic>>> getDriverReviews(String driverId) async {
    try {
      final snapshot = await _driverReviewsCollection
          .where('driverId', isEqualTo: driverId)
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
          'requestId': data['requestId'] as String,
        };
      }).toList();
    } catch (e) {
      print('Error getting driver reviews: $e');
      return [];
    }
  }

  /// ✅ NEW: Get vehicle reviews from NEW collection
  Future<List<Map<String, dynamic>>> getVehicleReviews(String vehicleId) async {
    try {
      final snapshot = await _vehicleReviewsCollection
          .where('vehicleId', isEqualTo: vehicleId)
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
          'requestId': data['requestId'] as String,
        };
      }).toList();
    } catch (e) {
      print('Error getting vehicle reviews: $e');
      return [];
    }
  }

  /// ✅ NEW: Get driver ratings history from NEW collection
  Future<List<Map<String, dynamic>>> getDriverRatingsHistory(
      String driverId) async {
    try {
      final snapshot = await _driverRatingsCollection
          .where('driverId', isEqualTo: driverId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'rating': data['rating'] is int
              ? (data['rating'] as int).toDouble()
              : data['rating'] as double,
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'requestId': data['requestId'] as String,
          'review': data['review'] as String?,
          'ratedAt': data['ratedAt'] as String?,
        };
      }).toList();
    } catch (e) {
      print('Error getting driver ratings history: $e');
      return [];
    }
  }

  /// ✅ NEW: Get vehicle ratings history from NEW collection
  Future<List<Map<String, dynamic>>> getVehicleRatingsHistory(
      String vehicleId) async {
    try {
      final snapshot = await _vehicleRatingsCollection
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'rating': data['rating'] is int
              ? (data['rating'] as int).toDouble()
              : data['rating'] as double,
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'requestId': data['requestId'] as String,
          'review': data['review'] as String?,
          'ratedAt': data['ratedAt'] as String?,
        };
      }).toList();
    } catch (e) {
      print('Error getting vehicle ratings history: $e');
      return [];
    }
  }

  /// Get ride request with updated ratings
  Future<RideRequestModel?> getRideRequestWithRatings(String requestId) async {
    try {
      final doc = await _rideRequestsCollection.doc(requestId).get();
      if (doc.exists) {
        final request = RideRequestModel.fromSnapshot(doc);
        print(
            'Retrieved request $requestId with driver rating: ${request.driverRating}, vehicle rating: ${request.vehicleRating}');
        return request;
      }
      return null;
    } catch (e) {
      print('Error getting ride request with ratings: $e');
      throw e;
    }
  }

  // VEHICLES
  // Get all vehicles
  Stream<List<VehicleModel>> getVehicles() {
    return _vehiclesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromSnapshot(doc))
          .toList();
    });
  }

  // Get available vehicles
  Stream<List<VehicleModel>> getAvailableVehicles() {
    return _vehiclesCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromSnapshot(doc))
          .toList();
    });
  }

  // Create a new vehicle
  Future<void> createVehicle(VehicleModel vehicle) async {
    // Check if license plate already exists
    QuerySnapshot existingVehicles = await _vehiclesCollection
        .where('licensePlate', isEqualTo: vehicle.licensePlate)
        .get();

    if (existingVehicles.docs.isNotEmpty) {
      throw Exception(
          'Vehicle with license plate ${vehicle.licensePlate} already exists.');
    }

    await _vehiclesCollection.add(vehicle.toMap());
  }

  // Update a vehicle
  Future<void> updateVehicle(VehicleModel vehicle) async {
    // Check if license plate already exists on another vehicle
    QuerySnapshot existingVehicles = await _vehiclesCollection
        .where('licensePlate', isEqualTo: vehicle.licensePlate)
        .get();

    if (existingVehicles.docs.isNotEmpty) {
      for (var doc in existingVehicles.docs) {
        if (doc.id != vehicle.id) {
          throw Exception(
              'Vehicle with license plate ${vehicle.licensePlate} already exists.');
        }
      }
    }

    await _vehiclesCollection.doc(vehicle.id).update(vehicle.toMap());
  }

  // Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    // Check if vehicle is used in any ride requests
    QuerySnapshot usedVehicles = await _rideRequestsCollection
        .where('vehicleId', isEqualTo: vehicleId)
        .limit(1)
        .get();

    if (usedVehicles.docs.isNotEmpty) {
      throw Exception('Cannot delete vehicle that is used in ride requests.');
    }

    await _vehiclesCollection.doc(vehicleId).delete();
  }

  // DRIVERS
  // Get all drivers
  Stream<List<DriverModel>> getDrivers() {
    return _driversCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DriverModel.fromSnapshot(doc)).toList();
    });
  }

  // Get available drivers
  Stream<List<DriverModel>> getAvailableDrivers() {
    return _driversCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DriverModel.fromSnapshot(doc)).toList();
    });
  }

  // Create a new driver
  Future<void> createDriver(DriverModel driver) async {
    // Check if driver with same name already exists
    QuerySnapshot existingDrivers =
        await _driversCollection.where('name', isEqualTo: driver.name).get();

    if (existingDrivers.docs.isNotEmpty) {
      throw Exception('Driver with name ${driver.name} already exists.');
    }

    await _driversCollection.add(driver.toMap());
  }

  // Update a driver
  Future<void> updateDriver(DriverModel driver) async {
    // Check if driver with same name already exists
    QuerySnapshot existingDrivers =
        await _driversCollection.where('name', isEqualTo: driver.name).get();

    if (existingDrivers.docs.isNotEmpty) {
      for (var doc in existingDrivers.docs) {
        if (doc.id != driver.id) {
          throw Exception('Driver with name ${driver.name} already exists.');
        }
      }
    }

    await _driversCollection.doc(driver.id).update(driver.toMap());
  }

  // Delete a driver
  Future<void> deleteDriver(String driverId) async {
    // Check if driver is used in any ride requests
    QuerySnapshot usedDrivers = await _rideRequestsCollection
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();

    if (usedDrivers.docs.isNotEmpty) {
      throw Exception(
          'Cannot delete driver that is assigned to ride requests.');
    }

    await _driversCollection.doc(driverId).delete();
  }

  // Synchronize driver and vehicle status to fix inconsistencies
  Future<void> syncDriverVehicleStatus() async {
    // Get all ride requests that are in progress
    final activeRequests = await _rideRequestsCollection
        .where('status', isEqualTo: 'inProgress')
        .get();

    // Sets to store active driver and vehicle IDs
    final Set<String> activeDriverIds = {};
    final Set<String> activeVehicleIds = {};

    // Collect all active drivers and vehicles
    for (final doc in activeRequests.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['driverId'] != null)
        activeDriverIds.add(data['driverId'] as String);
      if (data['vehicleId'] != null)
        activeVehicleIds.add(data['vehicleId'] as String);
    }

    // Create batch for atomic updates
    final batch = _firestore.batch();

    // Fix drivers that should be unavailable but are marked as available
    final availableDrivers =
        await _driversCollection.where('isAvailable', isEqualTo: true).get();

    for (final doc in availableDrivers.docs) {
      if (activeDriverIds.contains(doc.id)) {
        batch.update(_driversCollection.doc(doc.id), {
          'isAvailable': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Fixing inconsistent driver status: ${doc.id}');
      }
    }

    // Fix vehicles that should be unavailable but are marked as available
    final availableVehicles =
        await _vehiclesCollection.where('isAvailable', isEqualTo: true).get();

    for (final doc in availableVehicles.docs) {
      if (activeVehicleIds.contains(doc.id)) {
        batch.update(_vehiclesCollection.doc(doc.id), {
          'isAvailable': false,
          'status': 'in-use',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Fixing inconsistent vehicle status: ${doc.id}');
      }
    }

    // Fix drivers that should be available but are marked as unavailable
    final unavailableDrivers =
        await _driversCollection.where('isAvailable', isEqualTo: false).get();

    for (final doc in unavailableDrivers.docs) {
      if (!activeDriverIds.contains(doc.id)) {
        batch.update(_driversCollection.doc(doc.id), {
          'isAvailable': true,
          'currentVehicleId': null,
          'currentVehicleName': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
            'Fixing inconsistent driver status (should be available): ${doc.id}');
      }
    }

    // Fix vehicles that should be available but are marked as unavailable
    final unavailableVehicles =
        await _vehiclesCollection.where('isAvailable', isEqualTo: false).get();

    for (final doc in unavailableVehicles.docs) {
      if (!activeVehicleIds.contains(doc.id)) {
        batch.update(_vehiclesCollection.doc(doc.id), {
          'isAvailable': true,
          'status': 'available',
          'currentDriverId': null,
          'currentDriverName': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
            'Fixing inconsistent vehicle status (should be available): ${doc.id}');
      }
    }

    // Commit all changes
    await batch.commit();
    print('Driver and vehicle status synchronization completed');
  }

  // ✅ NEW: Analytics methods for NEW collections

  /// Get all ratings statistics from NEW collections
  Future<Map<String, dynamic>> getAllRatingsStatistics() async {
    try {
      // Get driver statistics
      final driverRatingsSnapshot = await _driverRatingsCollection.get();
      final vehicleRatingsSnapshot = await _vehicleRatingsCollection.get();

      // Calculate driver stats
      double totalDriverRating = 0;
      int totalDriverRatings = driverRatingsSnapshot.docs.length;

      for (var doc in driverRatingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = data['rating'] is int
            ? (data['rating'] as int).toDouble()
            : data['rating'] as double;
        totalDriverRating += rating;
      }

      // Calculate vehicle stats
      double totalVehicleRating = 0;
      int totalVehicleRatings = vehicleRatingsSnapshot.docs.length;

      for (var doc in vehicleRatingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = data['rating'] is int
            ? (data['rating'] as int).toDouble()
            : data['rating'] as double;
        totalVehicleRating += rating;
      }

      return {
        'driverStats': {
          'totalRatings': totalDriverRatings,
          'averageRating': totalDriverRatings > 0
              ? totalDriverRating / totalDriverRatings
              : 0.0,
        },
        'vehicleStats': {
          'totalRatings': totalVehicleRatings,
          'averageRating': totalVehicleRatings > 0
              ? totalVehicleRating / totalVehicleRatings
              : 0.0,
        },
        'overallStats': {
          'totalRatings': totalDriverRatings + totalVehicleRatings,
          'averageRating': (totalDriverRatings + totalVehicleRatings) > 0
              ? (totalDriverRating + totalVehicleRating) /
                  (totalDriverRatings + totalVehicleRatings)
              : 0.0,
        }
      };
    } catch (e) {
      print('Error getting all ratings statistics: $e');
      return {
        'driverStats': {'totalRatings': 0, 'averageRating': 0.0},
        'vehicleStats': {'totalRatings': 0, 'averageRating': 0.0},
        'overallStats': {'totalRatings': 0, 'averageRating': 0.0},
      };
    }
  }

  /// Get top rated drivers from NEW collection
  Future<List<Map<String, dynamic>>> getTopRatedDrivers(
      {int limit = 10}) async {
    try {
      // Get all drivers with ratings
      final driversSnapshot = await _driversCollection
          .where('totalRatings', isGreaterThan: 0)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> topDrivers = [];

      for (var doc in driversSnapshot.docs) {
        final driverData = doc.data() as Map<String, dynamic>;
        topDrivers.add({
          'id': doc.id,
          'name': driverData['name'],
          'averageRating': driverData['averageRating'] is int
              ? (driverData['averageRating'] as int).toDouble()
              : driverData['averageRating'] as double,
          'totalRatings': driverData['totalRatings'],
        });
      }

      return topDrivers;
    } catch (e) {
      print('Error getting top rated drivers: $e');
      return [];
    }
  }

  /// Get top rated vehicles from NEW collection
  Future<List<Map<String, dynamic>>> getTopRatedVehicles(
      {int limit = 10}) async {
    try {
      // Get all vehicles with ratings
      final vehiclesSnapshot = await _vehiclesCollection
          .where('totalRatings', isGreaterThan: 0)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> topVehicles = [];

      for (var doc in vehiclesSnapshot.docs) {
        final vehicleData = doc.data() as Map<String, dynamic>;
        topVehicles.add({
          'id': doc.id,
          'name': vehicleData['name'] ?? vehicleData['licensePlate'],
          'licensePlate': vehicleData['licensePlate'],
          'averageRating': vehicleData['averageRating'] is int
              ? (vehicleData['averageRating'] as int).toDouble()
              : vehicleData['averageRating'] as double,
          'totalRatings': vehicleData['totalRatings'],
        });
      }

      return topVehicles;
    } catch (e) {
      print('Error getting top rated vehicles: $e');
      return [];
    }
  }

  /// Get recent ratings from NEW collections
  Future<List<Map<String, dynamic>>> getRecentRatings({int limit = 20}) async {
    try {
      List<Map<String, dynamic>> recentRatings = [];

      // Get recent driver ratings
      final driverRatingsSnapshot = await _driverRatingsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit ~/ 2)
          .get();

      for (var doc in driverRatingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        recentRatings.add({
          'id': doc.id,
          'type': 'driver',
          'entityId': data['driverId'],
          'requestId': data['requestId'],
          'rating': data['rating'] is int
              ? (data['rating'] as int).toDouble()
              : data['rating'] as double,
          'review': data['review'],
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        });
      }

      // Get recent vehicle ratings
      final vehicleRatingsSnapshot = await _vehicleRatingsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit ~/ 2)
          .get();

      for (var doc in vehicleRatingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        recentRatings.add({
          'id': doc.id,
          'type': 'vehicle',
          'entityId': data['vehicleId'],
          'requestId': data['requestId'],
          'rating': data['rating'] is int
              ? (data['rating'] as int).toDouble()
              : data['rating'] as double,
          'review': data['review'],
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        });
      }

      // Sort by timestamp
      recentRatings.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      return recentRatings.take(limit).toList();
    } catch (e) {
      print('Error getting recent ratings: $e');
      return [];
    }
  }

  /// ✅ NEW: Check if NEW collections exist (for debugging)
  Future<Map<String, bool>> checkNewCollectionsExist() async {
    try {
      final driverRatingsExists =
          (await _driverRatingsCollection.limit(1).get()).docs.isNotEmpty;
      final driverReviewsExists =
          (await _driverReviewsCollection.limit(1).get()).docs.isNotEmpty;
      final vehicleRatingsExists =
          (await _vehicleRatingsCollection.limit(1).get()).docs.isNotEmpty;
      final vehicleReviewsExists =
          (await _vehicleReviewsCollection.limit(1).get()).docs.isNotEmpty;

      print('✅ Collection Status:');
      print(
          '- driver_ratings: ${driverRatingsExists ? "EXISTS" : "NOT EXISTS"}');
      print(
          '- driver_reviews: ${driverReviewsExists ? "EXISTS" : "NOT EXISTS"}');
      print(
          '- vehicle_ratings: ${vehicleRatingsExists ? "EXISTS" : "NOT EXISTS"}');
      print(
          '- vehicle_reviews: ${vehicleReviewsExists ? "EXISTS" : "NOT EXISTS"}');

      return {
        'driver_ratings': driverRatingsExists,
        'driver_reviews': driverReviewsExists,
        'vehicle_ratings': vehicleRatingsExists,
        'vehicle_reviews': vehicleReviewsExists,
      };
    } catch (e) {
      print('Error checking collections existence: $e');
      return {
        'driver_ratings': false,
        'driver_reviews': false,
        'vehicle_ratings': false,
        'vehicle_reviews': false,
      };
    }
  }
}
