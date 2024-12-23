import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notes/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:notes/models/event_database.dart';
import 'package:notes/main.dart';

class UserDatabase extends ChangeNotifier {
  late Database db;
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'users.db');

    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            email TEXT
          )
        ''');
      },
    );
  }

  Future<bool> register(String username, String password, {String? email}) async {
    try {
      await db.insert(
        'users',
        User(
          username: username,
          password: password,
          email: email,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } catch (e) {
      return false; // 用户名已存在
    }
  }

  Future<bool> _validateCredentials(String username, String password) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      _currentUser = User.fromMap(maps.first);
      return true;
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    final success = await _validateCredentials(username, password);
    if (success && _currentUser != null) {
      // 保存登录状态
      await saveLoginState(_currentUser!.id.toString(), _currentUser!.username);
      notifyListeners();
    }
    return success;
  }

  Future<void> saveLoginState(String userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('username', username);
  }

  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('username');
  }

  Future<bool> checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final username = prefs.getString('username');
    
    if (userId != null && username != null) {
      // 从数据库获取用户信息
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (maps.isNotEmpty) {
        _currentUser = User.fromMap(maps.first);
        notifyListeners();
        // 确保 EventDatabase 获取到用户ID
        Provider.of<EventDatabase>(navigatorKey.currentContext!, listen: false)
            .setCurrentUser(int.parse(userId));
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await clearLoginState();
    notifyListeners();
  }

  bool get isLoggedIn => _currentUser != null;
}
