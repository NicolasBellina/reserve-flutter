import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/lot_repository.dart';
import 'data/repository_native.dart'
    if (dart.library.js_interop) 'data/repository_web.dart';
import 'state/pantry_controller.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ReserveApp(repository: createRepository()));
}

class ReserveApp extends StatefulWidget {
  const ReserveApp({super.key, required this.repository});
  final LotRepository repository;
  @override
  State<ReserveApp> createState() => _ReserveAppState();
}

class _ReserveAppState extends State<ReserveApp> with WidgetsBindingObserver {
  late final PantryController controller;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = PantryController(widget.repository);
    unawaited(controller.load());
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => controller.refreshDates(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.refreshDates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    controller.dispose();
    unawaited(widget.repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Réserve',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF49334D),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F5FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F5FA),
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
    home: HomePage(controller: controller),
  );
}
