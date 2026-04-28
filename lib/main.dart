import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:copd_ai_health_app/screens/loading_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize formatting for the specific locale
  await initializeDateFormatting('pt_PT', null);
  await dotenv.load(fileName: ".env");
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistente de Saúde',
      theme: AppTheme.lightTheme,
      home: const LoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
