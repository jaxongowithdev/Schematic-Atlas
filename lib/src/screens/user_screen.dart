import 'package:flutter/material.dart';
import '../database/storage_manager.dart';
import '../models/config_model.dart';
import '../utils/visual_themes.dart';
import 'navigation_view.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _storage = StorageManager.instance;
  bool _isInitialized = false;
  ConfigModel? _config;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Seed database with initial data
      await _storage.seedDatabase();

      // Load config
      final config = await _storage.getConfig();

      setState(() {
        _config = config;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() {
        _config = ConfigModel(); // Use default config
        _isInitialized = true;
      });
    }
  }

  Future<void> _reloadConfig() async {
    try {
      final config = await _storage.getConfig();
      setState(() {
        _config = config;
      });
    } catch (e) {
      debugPrint('Error reloading config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _config == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading Schematic Atlas...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine theme based on config
    ThemeMode themeMode;
    switch (_config!.theme) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      key: ValueKey(_config!.theme), // Force rebuild when theme changes
      title: 'Schematic Atlas',
      debugShowCheckedModeBanner: false,
      theme: VisualThemes.lightTheme,
      darkTheme: VisualThemes.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      home: NavigationView(onSettingsChanged: _reloadConfig),
    );
  }
}
