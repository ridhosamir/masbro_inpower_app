import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/operasionalApp/firestore_service.dart';
import '../../../services/user_service.dart';
import '../../../models/operasionalApp/ride_request_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class CreateRideRequestScreen extends StatefulWidget {
  @override
  _CreateRideRequestScreenState createState() => _CreateRideRequestScreenState();
}

class _CreateRideRequestScreenState extends State<CreateRideRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final OperasionalFirestoreService _firestoreService = OperasionalFirestoreService();
  
  bool _isLoading = false;
  UserModel? currentUser;
  
  // Date and time controllers
  DateTime _pickupDate = DateTime.now().add(Duration(hours: 1));
  TimeOfDay _pickupTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
  
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  
  int _passengerCapacity = 1;
  bool _hasReturn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.user != null) {
      final userData = await userService.getUserData(authService.user!.uid);
      setState(() {
        currentUser = userData;
      });
    }
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectPickupDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _pickupDate) {
      setState(() {
        _pickupDate = DateTime(
          picked.year, 
          picked.month, 
          picked.day,
          _pickupTime.hour,
          _pickupTime.minute,
        );
      });
    }
  }

  Future<void> _selectPickupTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
    );
    if (picked != null && picked != _pickupTime) {
      setState(() {
        _pickupTime = picked;
        _pickupDate = DateTime(
          _pickupDate.year, 
          _pickupDate.month, 
          _pickupDate.day,
          _pickupTime.hour,
          _pickupTime.minute,
        );
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? _pickupDate.add(Duration(days: 1)),
      firstDate: _pickupDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _returnDate = DateTime(
          picked.year, 
          picked.month, 
          picked.day,
          _returnTime?.hour ?? 17,
          _returnTime?.minute ?? 0,
        );
        _returnTime ??= TimeOfDay(hour: 17, minute: 0);
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _returnTime = picked;
        if (_returnDate != null) {
          _returnDate = DateTime(
            _returnDate!.year, 
            _returnDate!.month, 
            _returnDate!.day,
            _returnTime!.hour,
            _returnTime!.minute,
          );
        } else {
          _returnDate = DateTime(
            _pickupDate.year, 
            _pickupDate.month, 
            _pickupDate.day,
            _returnTime!.hour,
            _returnTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    // Additional validation for dates
    if (_hasReturn && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a return date and time'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasReturn && _returnDate!.isBefore(_pickupDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Return date must be after pickup date'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final request = RideRequestModel(
        id: '',
        employeeId: authService.user!.uid,
        employeeName: currentUser!.name,
        pickupLocation: _pickupLocationController.text.trim(),
        pickupDateTime: _pickupDate,
        dropoffLocation: _dropoffLocationController.text.trim(),
        returnDateTime: _hasReturn ? _returnDate : null,
        passengerCapacity: _passengerCapacity,
        description: _descriptionController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createRideRequest(request);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride request submitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('[CREATE_REQUEST] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Ride Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Request Transportation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Provide details about your transportation needs',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Pickup Location
                  Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  CustomTextField(
                    labelText: 'Pickup Location',
                    hintText: 'Enter pickup location',
                    controller: _pickupLocationController,
                    prefixIcon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pickup location';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Pickup Date & Time
                  Text(
                    'Pickup Date & Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectPickupDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600]),
                                SizedBox(width: 10),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(_pickupDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selectPickupTime,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.grey[600]),
                                SizedBox(width: 10),
                                Text(
                                  _pickupTime.format(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Dropoff Location
                  Text(
                    'Dropoff Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  CustomTextField(
                    labelText: 'Dropoff Location',
                    hintText: 'Enter dropoff location',
                    controller: _dropoffLocationController,
                    prefixIcon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter dropoff location';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Return Trip Option
                  SwitchListTile(
                    title: Text(
                      'Need Return Trip?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(
                      'Select if you need a return trip',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: _hasReturn,
                    activeColor: Theme.of(context).primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _hasReturn = value;
                      });
                    },
                  ),
                  SizedBox(height: 8),

                  // Return Date & Time
                  if (_hasReturn) ...[
                    Text(
                      'Return Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectReturnDate,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                                  SizedBox(width: 10),
                                  Text(
                                    _returnDate == null
                                        ? 'Select Date'
                                        : DateFormat('MMM dd, yyyy').format(_returnDate!),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectReturnTime,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.grey[600]),
                                  SizedBox(width: 10),
                                  Text(
                                    _returnTime == null
                                        ? 'Select Time'
                                        : _returnTime!.format(context),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],

                  // Passenger Capacity
                  Text(
                    'Passenger Capacity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.grey[600]),
                      SizedBox(width: 10),
                      Text(
                        '$_passengerCapacity ${_passengerCapacity == 1 ? 'Passenger' : 'Passengers'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: _passengerCapacity > 1
                            ? () {
                                setState(() {
                                  _passengerCapacity--;
                                });
                              }
                            : null,
                        color: _passengerCapacity > 1
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400],
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            _passengerCapacity++;
                          });
                        },
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  CustomTextField(
                    labelText: 'Description',
                    hintText: 'Add details about your transportation needs...',
                    controller: _descriptionController,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please provide a description';
                      }
                      if (value.length < 10) {
                        return 'Please provide a more detailed description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),

                  // Submit Button
                  CustomButton(
                    text: 'Submit Request',
                    onPressed: _submitRequest,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: 16),

                  // Info Note
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[700]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your request will be reviewed by an officer. You will be notified when your request is approved and assigned.',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}