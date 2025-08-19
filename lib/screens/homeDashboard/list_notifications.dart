import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masbro_inpower_app/models/notification_model.dart';
import 'package:masbro_inpower_app/services/notification_list_service.dart';
import 'package:masbro_inpower_app/services/statusNotifications/notif_status_helper.dart';
import 'package:provider/provider.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late final NotificationListService _notificationListService;
  late Stream<List<DocumentSnapshot>> _notificationStream;

  bool _isSelectionMode = false;
  final Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    // Ambil instance service yang sudah ada dari Provider.
    _notificationListService =
        Provider.of<NotificationListService>(context, listen: false);
    // Panggil stream dari service yang sudah diinisialisasi dengan benar.
    _notificationStream = _notificationListService.getNotificationsStream();
  }

  void _toggleSelectionMode({String? initialSelectionId}) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedNotifications.clear();
      if (_isSelectionMode && initialSelectionId != null) {
        _selectedNotifications.add(initialSelectionId);
      }
    });
  }

  void _onNotificationTap(
      BuildContext context, NotificationModel notification) {
    final notificationListService =
        Provider.of<NotificationListService>(context, listen: false);
    if (_isSelectionMode) {
      setState(() {
        if (_selectedNotifications.contains(notification.id)) {
          _selectedNotifications.remove(notification.id);
        } else {
          _selectedNotifications.add(notification.id);
        }
      });
    } else {
      // Mark as read and navigate
      notificationListService.markAsRead(notification.id);
      final notificationHandler =
          Provider.of<NotificationService>(context, listen: false);
      notificationHandler.handleMessageNavigation(notification.data);
    }
  }

  void _onLongPress(NotificationModel notification) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
    }
    setState(() {
      _selectedNotifications.add(notification.id);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedNotifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirm Deletion'),
          ],
        ),
        content: Text(
            'Are you sure you want to permanently delete ${_selectedNotifications.length} selected notification(s)? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationListService
          .deleteMultipleNotifications(_selectedNotifications.toList());
      setState(() {
        _isSelectionMode = false;
        _selectedNotifications.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationListService =
        Provider.of<NotificationListService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '${_selectedNotifications.length} selected'
            : 'Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: const [],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed:
                  _selectedNotifications.isEmpty ? null : _deleteSelected,
              backgroundColor: _selectedNotifications.isEmpty
                  ? Colors.grey
                  : Colors.redAccent,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isSelected =
                  _selectedNotifications.contains(notification.id);
              return _buildNotificationCard(notification, isSelected);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification, bool isSelected) {
    // Tentukan warna latar belakang berdasarkan status isRead
    final cardColor = notification.isRead ? Colors.white : Colors.blue.shade50;
    // Tentukan ketebalan font judul
    final titleFontWeight =
        notification.isRead ? FontWeight.normal : FontWeight.bold;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      // Gunakan warna yang sudah ditentukan
      color: isSelected ? Colors.blue.shade100 : cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide(
                color: Colors.grey.shade200,
                width: 1), // Tambahkan border tipis
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onNotificationTap(context, notification),
        onLongPress: () => _onLongPress(notification),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _onNotificationTap(context, notification);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      _getIconForNotification(notification.data['collection']),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Tampilkan titik merah HANYA jika notifikasi belum dibaca
                  if (!notification.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        // Gunakan ketebalan font yang sudah ditentukan
                        fontWeight: titleFontWeight,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('d MMM yyyy, HH:mm')
                          .format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                  onSelected: (String result) {
                    if (result == 'delete') {
                      _toggleSelectionMode(initialSelectionId: notification.id);
                    } else if (result == 'mark_read') {
                      _notificationListService.markAsRead(notification.id);
                    } else if (result == 'mark_unread') {
                      _notificationListService.markAsUnread(notification.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    // Tampilkan opsi secara dinamis berdasarkan status 'isRead'
                    if (notification.isRead)
                      const PopupMenuItem<String>(
                        value: 'mark_unread',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_unread_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Mark as unread'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem<String>(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            Icon(Icons.drafts_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Mark as read'),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Remove this notification',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Notifications',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no new notifications at this time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  IconData _getIconForNotification(String? collection, {String? requestType}) {
    switch (collection) {
      case 'reports':
        return Icons.construction;
      case 'requests_resource':
        if (requestType == 'resource') {
          return Icons.supervisor_account;
        } else {
          return Icons.inventory;
        }
      case 'ride_requests':
        return Icons.directions_car;
      case 'bookings':
        return Icons.meeting_room;
      default:
        return Icons.notifications;
    }
  }
}
