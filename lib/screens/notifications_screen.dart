import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import 'player_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    _notifications = await _db.getNotifications();
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _markAsRead(int id) async {
    await _db.markNotificationAsRead(id);
    await _loadNotifications();
  }
  
  Future<void> _markAllAsRead() async {
    await _db.markAllNotificationsAsRead();
    await _loadNotifications();
  }
  
  Future<void> _deleteNotification(int id) async {
    await _db.deleteNotification(id);
    await _loadNotifications();
  }
  
  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) {
      return '${diff.inDays ~/ 7}w ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'MARK ALL READ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _EmptyNotifications()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['is_read'] == 1;
                    final songId = notification['song_id'];
                    
                    return GestureDetector(
                      onTap: () async {
                        await _markAsRead(notification['id']);
                        if (songId != null) {
                          final song = await _db.getSongById(songId);
                          if (song != null) {
                            final audioProvider = Provider.of<AudioProvider>(
                              context,
                              listen: false,
                            );
                            audioProvider.playSong(song);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlayerScreen(),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppColors.surfaceContainerLow
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: isRead
                              ? null
                              : Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getIconColor(notification['type']).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIcon(notification['type']),
                                color: _getIconColor(notification['type']),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['title'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['message'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(notification['created_at']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            IconButton(
                              onPressed: () => _deleteNotification(notification['id']),
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  IconData _getIcon(String type) {
    switch (type) {
      case 'comment':
        return Icons.comment_outlined;
      case 'like':
        return Icons.favorite_outline;
      case 'follow':
        return Icons.person_add_outlined;
      case 'upload':
        return Icons.cloud_upload_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
  
  Color _getIconColor(String type) {
    switch (type) {
      case 'comment':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'follow':
        return Colors.green;
      case 'upload':
        return AppColors.primary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When you get comments or likes, they\'ll appear here',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}