import 'package:flutter/material.dart';

class AppSettingScreen extends StatelessWidget {
  const AppSettingScreen({Key? key}) : super(key: key);

  static const Color backgroundDark = Color(0xFF0E121A);
  static const Color surfaceDark = Color(0xFF161B26);
  static const Color mutedText = Color(0xFF9AA3B2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        title: const Text('設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1F2735)),
          ),
          child: const Text(
            '設定画面は準備中です。',
            style: TextStyle(color: mutedText),
          ),
        ),
      ),
    );
  }
}
