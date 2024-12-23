import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:notes/models/event.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notes/services/notification_service.dart';

class EventDatabase extends ChangeNotifier {
  late Database db;
  final List<Event> currentEvents = [];
  final _notificationService = NotificationService();
  int? currentUserId; // 添加当前用户ID

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'events.db');

    db = await openDatabase(
      path,
      version: 3, // 增加版本号
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            title TEXT NOT NULL,
            type INTEGER NOT NULL,
            dateTime TEXT NOT NULL,
            location TEXT,
            notes TEXT,
            hasNotification INTEGER NOT NULL DEFAULT 0,
            notificationMinutesBefore INTEGER,
            color INTEGER,
            FOREIGN KEY (userId) REFERENCES users (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE events ADD COLUMN color INTEGER');
        }
        if (oldVersion < 3) {
          // 备份旧数据
          await db.execute('CREATE TABLE events_backup AS SELECT * FROM events');
          // 删除旧表
          await db.execute('DROP TABLE events');
          // 创建新表
          await db.execute('''
            CREATE TABLE events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER NOT NULL,
              title TEXT NOT NULL,
              type INTEGER NOT NULL,
              dateTime TEXT NOT NULL,
              location TEXT,
              notes TEXT,
              hasNotification INTEGER NOT NULL DEFAULT 0,
              notificationMinutesBefore INTEGER,
              color INTEGER,
              FOREIGN KEY (userId) REFERENCES users (id)
            )
          ''');
          // 将旧数据插入新表（假设默认用户ID为1）
          await db.execute('''
            INSERT INTO events (
              id, userId, title, type, dateTime, location, notes,
              hasNotification, notificationMinutesBefore, color
            )
            SELECT 
              id, 1, title, type, dateTime, location, notes,
              hasNotification, notificationMinutesBefore, color
            FROM events_backup
          ''');
          // 删除备份表
          await db.execute('DROP TABLE events_backup');
        }
      },
    );
    
    await fetchEvents();
    _scheduleNotifications();
  }

  // 设置当前用户
  Future<void> setCurrentUser(int userId) async {
    currentUserId = userId;
    await fetchEvents();
  }

  Future<void> createEvent(Event event) async {
    if (currentUserId == null) return;
    
    final id = await db.insert(
      'events',
      event.toMap(),
    );

    // 创建带有ID的新事件对象
    final eventWithId = Event(
      id: id,
      userId: event.userId,
      title: event.title,
      type: event.type,
      dateTime: event.dateTime,
      location: event.location,
      notes: event.notes,
      hasNotification: event.hasNotification,
      notificationMinutesBefore: event.notificationMinutesBefore,
      color: event.color,
    );

    if (event.hasNotification && event.notificationMinutesBefore != null) {
      await _notificationService.showNotification(eventWithId);
    }

    await fetchEvents();
  }

  Future<void> addEvent(Event event) async {
    if (currentUserId == null) return;

    final id = await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    await fetchEvents();
    _checkAndNotify(event.copyWith(id: id));
  }

  Future<void> updateEvent(Event event) async {
    if (event.id == null || currentUserId == null) return;

    await db.update(
      'events',
      event.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [event.id, currentUserId],
    );
    
    await fetchEvents();
    _checkAndNotify(event);
  }

  Future<void> deleteEvent(int id) async {
    if (currentUserId == null) return;

    await db.delete(
      'events',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, currentUserId],
    );
    
    await fetchEvents();
  }

  Future<void> fetchEvents() async {
    if (currentUserId == null) {
      currentEvents.clear();
      notifyListeners();
      return;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [currentUserId],
    );
    
    currentEvents.clear();
    currentEvents.addAll(
      maps.map((map) => Event.fromMap(map)).toList(),
    );
    
    notifyListeners();
  }

  void _scheduleNotifications() {
    for (final event in currentEvents) {
      _checkAndNotify(event);
    }
  }

  void _checkAndNotify(Event event) {
    if (!event.hasNotification || event.notificationMinutesBefore == null) return;

    final notificationTime = event.dateTime.subtract(
      Duration(minutes: event.notificationMinutesBefore!),
    );

    if (DateTime.now().isAfter(notificationTime) &&
        DateTime.now().isBefore(event.dateTime)) {
      _notificationService.showNotification(event);
    }
  }

  List<Event> getEventsForDay(DateTime day) {
    return currentEvents.where((event) {
      return event.dateTime.year == day.year &&
             event.dateTime.month == day.month &&
             event.dateTime.day == day.day;
    }).toList();
  }

  // 导出事件为JSON字符串
  Future<String> exportEvents() async {
    if (currentUserId == null) return '[]';

    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [currentUserId],
    );

    // 转换为JSON字符串
    final eventList = maps.map((map) => Event.fromMap(map).toJson()).toList();
    return '[${eventList.join(',')}]';
  }

  // 从JSON字符串导入事件
  Future<void> importEvents(String jsonString) async {
    if (currentUserId == null) return;

    try {
      print('Importing events: $jsonString'); // 调试信息

      // 移除可能的空白字符
      final cleanJson = jsonString.trim();
      if (!cleanJson.startsWith('[') || !cleanJson.endsWith(']')) {
        throw FormatException('Invalid JSON format: must be an array');
      }

      // 解析JSON字符串
      final content = cleanJson.substring(1, cleanJson.length - 1);
      if (content.isEmpty) return;

      // 分割事件JSON字符串
      List<String> eventJsons = [];
      int bracketCount = 0;
      String currentEvent = '';

      for (int i = 0; i < content.length; i++) {
        currentEvent += content[i];
        if (content[i] == '{') bracketCount++;
        if (content[i] == '}') bracketCount--;

        if (bracketCount == 0 && currentEvent.trim().isNotEmpty) {
          eventJsons.add(currentEvent.trim());
          currentEvent = '';
          // 跳过下一个逗号
          if (i + 1 < content.length && content[i + 1] == ',') i++;
        }
      }

      print('Found ${eventJsons.length} events to import'); // 调试信息

      // 开始事务
      await db.transaction((txn) async {
        for (final eventJson in eventJsons) {
          try {
            print('Processing event: $eventJson'); // 调试信息
            
            // 创建事件对象
            final event = Event.fromJson(eventJson);
            
            // 准备插入数据
            final eventMap = event.toMap()
              ..['userId'] = currentUserId // 使用当前用户ID
              ..remove('id'); // 移除原有ID
            
            print('Inserting event: $eventMap'); // 调试信息

            // 插入事件
            final id = await txn.insert(
              'events',
              eventMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            print('Inserted event with ID: $id'); // 调试信息

            // 处理通知
            if (event.hasNotification && event.notificationMinutesBefore != null) {
              final newEvent = event.copyWith(id: id);
              await _notificationService.showNotification(newEvent);
            }
          } catch (e) {
            print('Error processing event: $e'); // 调试信息
            rethrow;
          }
        }
      });

      // 刷新事件列表
      await fetchEvents();
      print('Events refreshed successfully'); // 调试信息
    } catch (e) {
      print('Import failed: $e'); // 调试信息
      rethrow;
    }
  }
}
