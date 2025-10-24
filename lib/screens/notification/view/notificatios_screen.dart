import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shop/screens/order/views/orders_screen.dart';

// Notification model
class NotificationModel {
  final int? id;
  final String title;
  final String body;
  final String? data;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'data': data,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_read': isRead ? 1 : 0,
      };

  static NotificationModel fromMap(Map<String, dynamic> m) => NotificationModel(
        id: m['id'] as int?,
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        data: m['data'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        isRead: (m['is_read'] as int? ?? 0) == 1,
      );
}

// SQLite helper
class _NotificationDatabase {
  static final _NotificationDatabase _instance = _NotificationDatabase._internal();
  Database? _db;
  _NotificationDatabase._internal();
  factory _NotificationDatabase() => _instance;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'notifications.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE notifications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            data TEXT,
            created_at INTEGER NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> insert(NotificationModel n) async => (await db).insert('notifications', n.toMap());
  Future<List<NotificationModel>> all() async {
    final rows = await (await db).query('notifications', orderBy: 'created_at DESC');
    return rows.map(NotificationModel.fromMap).toList();
  }

  Future<int> unreadCount() async {
    final res = await (await db).rawQuery('SELECT COUNT(*) c FROM notifications WHERE is_read = 0');
    final v = res.first['c'];
    return v is int ? v : (v as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead() async => (await db).update('notifications', {'is_read': 1}, where: 'is_read = 0');
  Future<void> delete(int id) async => (await db).delete('notifications', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteAll() async => (await db).delete('notifications');
}

// Service facade
class NotificationService {
  final _db = _NotificationDatabase();

  Future<void> saveFromFCM(RemoteMessage message) async {
    final model = NotificationModel(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data.isNotEmpty ? jsonEncode(message.data) : null,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _db.insert(model);
  }

  Future<List<NotificationModel>> getAll() => _db.all();
  Future<int> getUnreadCount() => _db.unreadCount();
  Future<void> markAllAsRead() => _db.markAllRead();
  Future<void> delete(int id) => _db.delete(id);
  Future<void> deleteAll() => _db.deleteAll();
}

// Notifications UI
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _service.getAll();
    await _service.markAllAsRead();
    if (mounted) setState(() { _items = all; _loading = false; });
  }

  Future<void> _delete(int id) async {
    await _service.delete(id);
    _load();
  }

  Future<void> _deleteAll() async {
    await _service.deleteAll();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          // Deletion controls removed to prevent deleting notifications from UI
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You will see notifications here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      // No delete UI — show notification item only
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.notifications)),
                        title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(_ago(n.createdAt), style: Theme.of(context).textTheme.bodySmall),
                        onTap: () async {
                          // If notification contains JSON data with an order_id, navigate to OrdersScreen.
                          if (n.data != null) {
                            try {
                              final Map<String, dynamic> d = jsonDecode(n.data!);
                              final orderId = d['order_id'] ?? d['orderId'] ?? d['id'];
                              if (orderId != null) {
                                // Navigate to orders screen (you can extend OrdersScreen to accept an order id if needed)
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                                );
                                return;
                              }
                            } catch (_) {
                              // ignore JSON parse errors and fall back to detail view
                            }
                          }
                          // Default behaviour: show detail dialog (does not delete notification)
                          _showDetail(n);
                        },
                      );
                    },
                  ),
                )),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }

  void _showDetail(NotificationModel n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(n.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.body),
              if (n.data != null) ...[
                const SizedBox(height: 12),
                Text('Data:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(n.data!),
              ],
              const SizedBox(height: 12),
              Text('Received: ${_ago(n.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
