import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/model_download_screen.dart';
import 'screens/village_selection_screen.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize flutter_gemma
  await FlutterGemma.initialize(
    maxDownloadRetries: 5,
  );

  // Initialize sync service (starts connectivity monitoring)
  await SyncService.instance.initialize();

  runApp(const FieldAgentApp());
}

class FieldAgentApp extends StatelessWidget {
  const FieldAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldAgent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppRouter(),
    );
  }
}

/// Handles routing: model check → village check → home
class _AppRouter extends StatefulWidget {
  const _AppRouter();
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool? _modelInstalled;
  String? _selectedVillage;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final modelInstalled = await FlutterGemma.isModelInstalled('gemma-4-E4B-it.litertlm');
    final prefs = await SharedPreferences.getInstance();
    final village = prefs.getString('selected_village');
    debugPrint('[AppRouter] modelInstalled=$modelInstalled village="$village"');
    if (mounted) {
      setState(() {
        _modelInstalled = modelInstalled;
        _selectedVillage = village;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still loading
    if (_modelInstalled == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Model not downloaded → show download screen
    if (!_modelInstalled!) {
      return ModelDownloadScreen(
        onModelReady: () => setState(() {
          _modelInstalled = true;
          _selectedVillage = null; // Proceed to village selection
        }),
      );
    }

    // Village not selected (or was skipped) → show village selection
    if (_selectedVillage == null || _selectedVillage!.isEmpty) {
      return VillageSelectionScreen(
        onVillageSelected: (village) {
          setState(() => _selectedVillage = village);
        },
      );
    }

    // All set → Home
    return HomeScreen(village: _selectedVillage!);
  }
}
