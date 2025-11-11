import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_lembretes/screens/home_screen.dart';
import 'package:app_lembretes/services/notification_service.dart';
import 'package:app_lembretes/services/firestore_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  // Garantir que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar dados de localização de data/hora
  await initializeDateFormatting('pt_BR', null);

  // Inicializar dados de fuso horário
  tz.initializeTimeZones();

  // Configurar timezone do Brasil
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

  // Inicializar o serviço de notificação
  await NotificationService().init();

  // Garantir autenticação anônima
  await FirestoreService().ensureAuthenticated();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Personalização: Tema com cores suaves
    final softTheme = ThemeData(
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.teal[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal[400],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)
          .copyWith(secondary: Colors.amber[600]),
    );

    return MaterialApp(
      title: 'App de Lembretes - Firebase',
      theme: softTheme,
      debugShowCheckedModeBanner: false,
      // Adiciona suporte a localizações em português
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      home: const HomeScreen(),
    );
  }
}