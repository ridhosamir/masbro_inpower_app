import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/maintenanceApp/firestore_service.dart';
import '../../../models/maintenanceApp/building_model.dart';
import '../../../models/maintenanceApp/room_model.dart';
import '../../../widgets/custom_text_field.dart';

class RoomManagementScreen extends StatefulWidget {
  @override
  _RoomManagementScreenState createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _roomNameController = TextEditingController();
  final _roomSearchController =
      TextEditingController(); // Controller for room search
  bool _isAddingRoom = false;
  bool _isLoading = false;
  RoomModel? _selectedRoom;
  BuildingModel? _selectedBuilding;
  String? _selectedBuildingId;
  String _filterBuildingId = '';
  bool _isInitialized = false;
  String _roomSearchQuery = ''; // Track room search query

  @override
  void initState() {
    super.initState();
    _findBuildingWithMostRooms();
    _roomSearchController.addListener(_onRoomSearchChanged);
  }

  // Room search listener
  void _onRoomSearchChanged() {
    setState(() {
      _roomSearchQuery = _roomSearchController.text.toLowerCase();
    });
  }

  // Clear room search
  void _clearRoomSearch() {
    _roomSearchController.clear();
  }

  Future<void> _findBuildingWithMostRooms() async {
    // Wait for buildings stream to get data
    _firestoreService.getBuildings().first.then((buildings) async {
      if (buildings.isEmpty) return;

      // Track the count of rooms per building
      Map<String, int> roomCounts = {};
      String buildingIdWithMostRooms = '';
      int maxRooms = 0;

      // Initialize room counts for all buildings
      for (var building in buildings) {
        roomCounts[building.id] = 0;
      }

      // Get all rooms
      final rooms = await _firestoreService.getRooms().first;

      // Count rooms per building
      for (var room in rooms) {
        if (roomCounts.containsKey(room.buildingId)) {
          roomCounts[room.buildingId] = (roomCounts[room.buildingId] ?? 0) + 1;
        }
      }

      // Find the building with most rooms
      roomCounts.forEach((buildingId, count) {
        if (count > maxRooms) {
          maxRooms = count;
          buildingIdWithMostRooms = buildingId;
        }
      });

      // If we found a building with rooms, set it as the default filter
      if (buildingIdWithMostRooms.isNotEmpty) {
        setState(() {
          _filterBuildingId = buildingIdWithMostRooms;
          _isInitialized = true;
        });
      } else if (buildings.isNotEmpty) {
        // If no building has rooms, just select the first building
        setState(() {
          _filterBuildingId = buildings.first.id;
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomSearchController.dispose(); // Dispose room search controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Room Management',
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Room Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add, edit, or delete rooms. Each room must be assigned to a building.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Add room section
              _isAddingRoom
                  ? _buildAddRoomForm()
                  : ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAddingRoom = true;
                          _selectedRoom = null;
                          _selectedBuildingId = null;
                          _roomNameController.clear();
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add New Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
              SizedBox(height: 24),

              // Filter by building
              _buildBuildingFilter(),
              SizedBox(height: 16),

              // Room search field
              _buildRoomSearchField(),
              SizedBox(height: 16),

              // Rooms list title
              Text(
                'All Rooms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),

              // Rooms list
              Expanded(
                child: _buildRoomsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Room search field widget
  Widget _buildRoomSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _roomSearchController,
        decoration: InputDecoration(
          hintText: 'Search rooms...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _roomSearchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: _clearRoomSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBuildingFilter() {
    return StreamBuilder<List<BuildingModel>>(
      stream: _firestoreService.getBuildings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final buildings = snapshot.data ?? [];

        if (buildings.isEmpty) {
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No buildings available. Please add buildings first.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }

        // If we haven't initialized yet and we have buildings, select the first one
        if (!_isInitialized && buildings.isNotEmpty) {
          // Set a default building if none is selected yet
          Future.microtask(() {
            setState(() {
              _filterBuildingId = buildings.first.id;
              _isInitialized = true;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Building',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            _buildSearchableBuildingDropdown(buildings),
          ],
        );
      },
    );
  }

  // Searchable Building Dropdown
  Widget _buildSearchableBuildingDropdown(List<BuildingModel> buildings) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildBuildingSearchModal(buildings),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _filterBuildingId.isEmpty
                    ? 'Select a building'
                    : buildings
                        .firstWhere(
                          (building) => building.id == _filterBuildingId,
                          orElse: () => buildings.first,
                        )
                        .name,
                style: TextStyle(
                  color: _filterBuildingId.isEmpty
                      ? Colors.grey[600]
                      : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.search, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // Building Search Modal
  Widget _buildBuildingSearchModal(List<BuildingModel> buildings) {
    TextEditingController searchController = TextEditingController();
    List<BuildingModel> filteredBuildings = List.from(buildings);

    return StatefulBuilder(
      builder: (context, setState) {
        void updateSearch(String query) {
          setState(() {
            filteredBuildings = buildings
                .where((building) =>
                    building.name.toLowerCase().contains(query.toLowerCase()))
                .toList();
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Building',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Search field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: searchController,
                  onChanged: updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search buildings...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  autofocus: true,
                ),
              ),
              // Buildings list
              Expanded(
                child: filteredBuildings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No buildings found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredBuildings.length,
                        itemBuilder: (context, index) {
                          final building = filteredBuildings[index];
                          final isSelected = building.id == _filterBuildingId;

                          return ListTile(
                            title: Text(building.name),
                            tileColor: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : null,
                            leading: isSelected
                                ? Icon(Icons.check_circle, color: Colors.blue)
                                : Icon(Icons.circle_outlined,
                                    color: Colors.grey),
                            onTap: () {
                              this.setState(() {
                                _filterBuildingId = building.id;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddRoomForm() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRoom == null ? 'Add New Room' : 'Edit Room',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),

          // Building selection
          Text(
            'Select Building',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<List<BuildingModel>>(
            stream: _firestoreService.getBuildings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final buildings = snapshot.data ?? [];

              if (buildings.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No buildings available. Please add buildings first.',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        _buildFormBuildingSearchModal(buildings),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedBuildingId != null
                              ? buildings
                                  .firstWhere(
                                    (building) =>
                                        building.id == _selectedBuildingId,
                                    orElse: () => BuildingModel(
                                        id: '',
                                        name: 'Unknown',
                                        createdAt: DateTime.now()),
                                  )
                                  .name
                              : 'Select a building',
                          style: TextStyle(
                            color: _selectedBuildingId != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.search, color: Colors.grey[600]),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),

          // Room name
          Text(
            'Room Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          CustomTextField(
            labelText: 'Room Name',
            hintText: 'Enter room name',
            controller: _roomNameController,
          ),
          SizedBox(height: 24),

          // Form buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isAddingRoom = false;
                            _selectedRoom = null;
                            _selectedBuildingId = null;
                            _roomNameController.clear();
                          });
                        },
                  child: Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRoom,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Text(
                          _selectedRoom == null ? 'Add Room' : 'Update Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Form Building Search Modal
  Widget _buildFormBuildingSearchModal(List<BuildingModel> buildings) {
    TextEditingController searchController = TextEditingController();
    List<BuildingModel> filteredBuildings = List.from(buildings);

    return StatefulBuilder(
      builder: (context, setState) {
        void updateSearch(String query) {
          setState(() {
            filteredBuildings = buildings
                .where((building) =>
                    building.name.toLowerCase().contains(query.toLowerCase()))
                .toList();
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Building',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Search field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: searchController,
                  onChanged: updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search buildings...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  autofocus: true,
                ),
              ),
              // Buildings list
              Expanded(
                child: filteredBuildings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No buildings found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredBuildings.length,
                        itemBuilder: (context, index) {
                          final building = filteredBuildings[index];
                          final isSelected = building.id == _selectedBuildingId;

                          return ListTile(
                            title: Text(building.name),
                            tileColor: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : null,
                            leading: isSelected
                                ? Icon(Icons.check_circle, color: Colors.blue)
                                : Icon(Icons.circle_outlined,
                                    color: Colors.grey),
                            onTap: () {
                              this.setState(() {
                                _selectedBuildingId = building.id;
                                _selectedBuilding = building;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomsList() {
    return StreamBuilder<List<RoomModel>>(
      stream: _filterBuildingId.isEmpty
          ? _firestoreService.getRooms()
          : _firestoreService.getRoomsByBuilding(_filterBuildingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allRooms = snapshot.data ?? [];

        // Filter rooms based on search query
        final rooms = _roomSearchQuery.isEmpty
            ? allRooms
            : allRooms
                .where((room) =>
                    room.name.toLowerCase().contains(_roomSearchQuery) ||
                    room.buildingName.toLowerCase().contains(_roomSearchQuery))
                .toList();

        if (allRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No rooms in this building',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Click the "Add New Room" button to add a room',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No rooms match your search',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try a different search term or clear the search',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _clearRoomSearch,
                  icon: Icon(Icons.clear, color: Colors.red),
                  label: Text('Clear Search',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: Colors.purple[700],
                  ),
                ),
                title: _roomSearchQuery.isEmpty
                    ? Text(
                        room.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : _highlightSearchText(room.name, _roomSearchQuery),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _roomSearchQuery.isEmpty
                          ? Text(
                              room.buildingName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            )
                          : _highlightSearchText(
                              room.buildingName,
                              _roomSearchQuery,
                              TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Added on ${_formatDate(room.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _selectedRoom = room;
                          _selectedBuildingId = room.buildingId;
                          _roomNameController.text = room.name;
                          _isAddingRoom = true;
                        });
                      },
                      tooltip: 'Edit Room',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteRoom(room),
                      tooltip: 'Delete Room',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper to highlight search text
  Widget _highlightSearchText(String text, String searchQuery,
      [TextStyle? baseStyle]) {
    final defaultStyle = baseStyle ??
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        );

    if (searchQuery.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    final matches = <Match>[];
    final pattern = RegExp(searchQuery, caseSensitive: false);
    pattern.allMatches(text).forEach((match) {
      matches.add(match);
    });

    if (matches.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    final List<TextSpan> children = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add highlighted match
      children.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: defaultStyle.copyWith(
          backgroundColor: Colors.yellow[200],
          color: Colors.black,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add text after the last match
    if (lastMatchEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return RichText(text: TextSpan(children: children));
  }

  Future<void> _saveRoom() async {
    final roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter room name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedBuildingId == null || _selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a building'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRoom == null) {
        // Adding new room
        final room = RoomModel(
          id: '',
          buildingId: _selectedBuildingId!,
          buildingName: _selectedBuilding!.name,
          name: roomName,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createRoom(room);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Updating existing room
        final updatedRoom = _selectedRoom!.copyWith(
          buildingId: _selectedBuildingId!,
          buildingName: _selectedBuilding!.name,
          name: roomName,
        );
        await _firestoreService.updateRoom(updatedRoom);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _isAddingRoom = false;
        _selectedRoom = null;
        _selectedBuildingId = null;
        _roomNameController.clear();
      });
    } catch (e) {
      String errorMessage = e.toString();
      // Extract more user-friendly error message if it's our validation error
      if (errorMessage.contains('Room with the name')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmDeleteRoom(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Room'),
        content: Text(
          'Are you sure you want to delete "${room.name}" from building "${room.buildingName}"? This action cannot be undone.\n\n'
          'Note: You cannot delete a room that is used in reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteRoom(room.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                String errorMessage = e.toString();
                if (errorMessage.contains('Cannot delete room')) {
                  errorMessage = errorMessage.replaceAll('Exception: ', '');
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $errorMessage'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
