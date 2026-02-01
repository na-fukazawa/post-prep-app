import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/app_shell.dart';
import 'services/app_navigator.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '投稿準備',
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const AppShell(),
    );
  }
}
