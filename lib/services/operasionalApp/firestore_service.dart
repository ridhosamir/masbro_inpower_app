import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/operasionalApp/ride_request_model.dart';
import '../../models/operasionalApp/vehicle_model.dart';
import '../../models/operasionalApp/driver_model.dart';

class OperasionalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _rideRequestsCollection =
      FirebaseFirestore.instance.collection('ride_requests');
  final CollectionReference _vehiclesCollection =
      FirebaseFirestore.instance.collection('vehicles');
  final CollectionReference _driversCollection =
      FirebaseFirestore.instance.collection('drivers');

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
      'status': 'in-use', // For consistency if using status field
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
}
