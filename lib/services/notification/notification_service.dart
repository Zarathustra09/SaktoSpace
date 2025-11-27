import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_messaging/firebase_messaging.dart';

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
        await d.execute('CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at)');
      },
    );
    // Debug log: DB opened (useful in background isolate)
    print('[DB] Opened at $path');
    return _db!;
  }

  Future<int> insert(NotificationModel n) async {
    // Dedup within 10s by title+body
    final from = n.createdAt.subtract(const Duration(seconds: 10)).millisecondsSinceEpoch;
    final to = n.createdAt.add(const Duration(seconds: 10)).millisecondsSinceEpoch;
    final existing = await (await db).query(
      'notifications',
      where: 'title = ? AND body = ? AND created_at BETWEEN ? AND ?',
      whereArgs: [n.title, n.body, from, to],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    final id = await (await db).insert('notifications', n.toMap());
    // print('[DB] Inserted notification id=$id');
    return id;
  }

  Future<List<NotificationModel>> all() async {
    final rows = await (await db).query('notifications', orderBy: 'created_at DESC');
    return rows.map(NotificationModel.fromMap).toList();
  }

  Future<int> unreadCount() async {
    final res =
        await (await db).rawQuery('SELECT COUNT(*) c FROM notifications WHERE is_read = 0');
    final v = res.first['c'];
    return v is int ? v : (v as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead() async =>
      (await db).update('notifications', {'is_read': 1}, where: 'is_read = 0');

  Future<void> delete(int id) async =>
      (await db).delete('notifications', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteAll() async => (await db).delete('notifications');
}

class NotificationService {
  final _db = _NotificationDatabase();

  Future<void> saveFromFCM(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      // Prefer server created_at when present
      DateTime created = DateTime.now();
      final createdAtStr = message.data['created_at'];
      if (createdAtStr is String && createdAtStr.isNotEmpty) {
        try {
          created = DateTime.parse(createdAtStr);
        } catch (_) {}
      }

      final model = NotificationModel(
        title: title,
        body: body,
        data: message.data.isNotEmpty ? jsonEncode(message.data) : null,
        createdAt: created,
        isRead: false,
      );

      await _db.insert(model);
      // print('[Service] Saved notification: ${model.title}');
    } catch (_) {
      // swallow to avoid crashes in background isolate
    }
  }

  Future<List<NotificationModel>> getAll() => _db.all();
  Future<int> getUnreadCount() => _db.unreadCount();
  Future<void> markAllAsRead() => _db.markAllRead();
  Future<void> delete(int id) => _db.delete(id);
  Future<void> deleteAll() => _db.deleteAll();
}
