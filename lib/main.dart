import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/divination_provider.dart';
import 'providers/history_provider.dart';
import 'algorithms/shouxing_calendar.dart';
import 'screens/home_screen.dart';
import 'screens/manual_input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/shake_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  // 确保Flutter绑定初始化（用于加载assets）
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化节气表
  await ShouXingCalendar.init();
  runApp(const LiuYaoApp());
}

class LiuYaoApp extends StatelessWidget {
  const LiuYaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DivinationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: '六爻排盘',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D4037), // 棕色系
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F0E8), // 宣纸色背景
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF8B4513),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/manual': (context) => const ManualInputScreen(),
          '/shake': (context) => const ShakeScreen(),
          '/result': (context) => const ResultScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}