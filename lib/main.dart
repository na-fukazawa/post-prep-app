import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/schduleed_annoucements.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '投稿準備',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const SchduleedAnnoucementsScreen(),
    );
  }
}
