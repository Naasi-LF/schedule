import 'package:flutter/material.dart';
import 'package:notes/models/event_database.dart';
import 'package:notes/pages/events_page.dart';
import 'package:notes/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:notes/services/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:notes/models/user_database.dart';
import 'package:notes/pages/login_page.dart';
import 'dart:async';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  debugPrint('Notification action received: ${receivedAction.toMap()}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize databases
  final userDatabase = UserDatabase();
  await userDatabase.init();

  final eventDatabase = EventDatabase();
  await eventDatabase.init();

  // Set up periodic timer to check event times
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final currentTime = DateTime.now();
    debugPrint('Checking events at: ${currentTime.toIso8601String()}');
    final events = eventDatabase.currentEvents;
    for (var event in events) {
      if (!event.hasNotification || event.notificationMinutesBefore == null) {
        continue;
      }

      final notificationTime = event.dateTime
          .subtract(Duration(minutes: event.notificationMinutesBefore!));
      debugPrint(
          'Checking event: ${event.title} scheduled for ${event.dateTime.toIso8601String()}, notification time: ${notificationTime.toIso8601String()}');

      if (currentTime.year == notificationTime.year &&
          currentTime.month == notificationTime.month &&
          currentTime.day == notificationTime.day &&
          currentTime.hour == notificationTime.hour &&
          currentTime.minute == notificationTime.minute) {
        debugPrint('Event notification time matched: ${event.title}');
        await notificationService.showNotification(event);
      }
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider.value(value: userDatabase),
        ChangeNotifierProvider.value(value: eventDatabase),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: FutureBuilder(
            future: Provider.of<UserDatabase>(context, listen: false).checkLoginState(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final bool isLoggedIn = snapshot.data ?? false;
              return isLoggedIn ? const EventsPage() : const LoginPage();
            },
          ),
        );
      },
    );
  }
}
