// event.dart

enum EventType { birthday, meeting, homework, exam, other }

class Event {
  final int? id;
  final int userId;
  final String title;
  final EventType type;
  final DateTime dateTime;
  final String? location;
  final String? notes;
  final bool hasNotification;
  final int? notificationMinutesBefore;
  final int? color;

  Event({
    this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.dateTime,
    this.location,
    this.notes,
    this.hasNotification = false,
    this.notificationMinutesBefore,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.index,
      'dateTime': dateTime.toIso8601String(),
      'location': location ?? '',
      'notes': notes ?? '',
      'hasNotification': hasNotification ? 1 : 0,
      'notificationMinutesBefore': notificationMinutesBefore,
      'color': color,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      userId: map['userId'],
      title: map['title'] ?? '',
      type: EventType.values[map['type'] ?? 0],
      dateTime: map['dateTime'] is String 
          ? DateTime.parse(map['dateTime']) 
          : map['dateTime'] ?? DateTime.now(),
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      hasNotification: map['hasNotification'] == 1,
      notificationMinutesBefore: map['notificationMinutesBefore'],
      color: map['color'],
    );
  }

  Event copyWith({
    int? id,
    int? userId,
    String? title,
    EventType? type,
    DateTime? dateTime,
    String? location,
    String? notes,
    bool? hasNotification,
    int? notificationMinutesBefore,
    int? color,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
      color: color ?? this.color,
    );
  }

  // 转换为JSON字符串
  String toJson() {
    final map = toMap();
    final buffer = StringBuffer('{');
    var first = true;
    
    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      
      if (value == null) {
        buffer.write('"$key":null');
      } else if (value is bool || value is num) {
        buffer.write('"$key":$value');
      } else if (value is DateTime) {
        buffer.write('"$key":"${value.toIso8601String()}"');
      } else {
        buffer.write('"$key":"$value"');
      }
    });
    
    buffer.write('}');
    return buffer.toString();
  }

  // 从JSON字符串创建Event对象
  factory Event.fromJson(String json) {
    // 移除首尾的大括号
    final content = json.trim();
    if (!content.startsWith('{') || !content.endsWith('}')) {
      throw FormatException('Invalid JSON format: must be an object');
    }

    final map = <String, dynamic>{};
    final pairs = content.substring(1, content.length - 1).split(',');
    
    for (var pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll('"', '');
        var value = parts[1].trim();
        
        // 处理不同类型的值
        if (value == 'null') {
          map[key] = null;
        } else if (value == 'true') {
          map[key] = true;
        } else if (value == 'false') {
          map[key] = false;
        } else if (value.startsWith('"') && value.endsWith('"')) {
          // 字符串值
          value = value.substring(1, value.length - 1);
          if (key == 'dateTime') {
            map[key] = DateTime.parse(value);
          } else {
            map[key] = value;
          }
        } else if (int.tryParse(value) != null) {
          map[key] = int.parse(value);
        } else {
          map[key] = value;
        }
      }
    }
    
    return Event.fromMap(map);
  }

  @override
  String toString() {
    return 'Event{id: $id, userId: $userId, title: $title, type: $type, dateTime: $dateTime, location: $location, notes: $notes, hasNotification: $hasNotification, notificationMinutesBefore: $notificationMinutesBefore, color: $color}';
  }
}
