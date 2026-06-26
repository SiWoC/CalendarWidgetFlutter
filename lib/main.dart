import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'calendar_permission.dart';
import 'calendar_platform_channel.dart';
import 'calendar_widget_data.dart';
import 'widget_settings.dart';
import 'widgets/calendar_permission_banner.dart';
import 'widgets/calendar_preview_frame.dart';

void main() {
  runApp(const CalendarWidgetApp());
}

class CalendarWidgetApp extends StatelessWidget {
  const CalendarWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar Widget',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const CalendarHomePage(),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage>
    with WidgetsBindingObserver {
  WidgetSettings? _settings;
  CalendarWidgetData? _data;
  bool _isRefreshing = false;
  bool _calendarGranted = false;
  bool _permanentlyDenied = false;
  Uint8List? _wallpaperPng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPermissionState(requestIfNeeded: false);
      _loadWallpaper(requestIfNeeded: false);
    }
  }

  Future<bool> _ensureWallpaperAccess({required bool requestIfNeeded}) async {
    final storage = await Permission.storage.status;
    final photos = await Permission.photos.status;
    if (storage.isGranted || photos.isGranted) return true;
    if (!requestIfNeeded) return false;

    debugPrint('Wallpaper access: storage=$storage, photos=$photos');

    final results = await [Permission.storage, Permission.photos].request();
    return (results[Permission.storage]?.isGranted ?? false) ||
        (results[Permission.photos]?.isGranted ?? false);
  }

  Future<void> _loadWallpaper({bool requestIfNeeded = true}) async {
    if (!await _ensureWallpaperAccess(requestIfNeeded: requestIfNeeded)) {
      return;
    }

    try {
      final bytes = await CalendarPlatformChannel.getWallpaper();
      if (!mounted) return;
      setState(() => _wallpaperPng = bytes);
    } on PlatformException catch (error) {
      debugPrint(
        'Wallpaper failed: code=${error.code}, message=${error.message}',
      );
      // Preview falls back to a neutral backdrop.
    }
  }

  Future<void> _loadInitialState() async {
    final settings = await WidgetSettings.load();
    final cached = await CalendarWidgetData.loadFromPrefs();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _data = cached;
    });
    await _syncPermissionState(requestIfNeeded: true);
    await _loadWallpaper(requestIfNeeded: true);
  }

  Future<void> _syncPermissionState({required bool requestIfNeeded}) async {
    final granted = requestIfNeeded
        ? await CalendarPermission.ensureGranted()
        : await CalendarPermission.isGranted;
    final permanentlyDenied =
        !granted && await CalendarPermission.isPermanentlyDenied;
    if (!mounted) return;
    setState(() {
      _calendarGranted = granted;
      _permanentlyDenied = permanentlyDenied;
    });
    if (granted) {
      try {
        await CalendarPlatformChannel.schedulePeriodicRefresh();
      } on PlatformException catch (error) {
        debugPrint(
          'schedulePeriodicRefresh failed: code=${error.code}, message=${error.message}',
        );
      }
      await _refresh();
    }
  }

  Future<void> _requestPermission() async {
    await _syncPermissionState(requestIfNeeded: true);
  }

  Future<void> _openSettings() async {
    await CalendarPermission.openSettings();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final data = await CalendarPlatformChannel.refresh();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isRefreshing = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      _showSnackBar('Vernieuwen mislukt: ${error.message ?? error.code}');
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      _showSnackBar(error.message);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final previewHeight = MediaQuery.sizeOf(context).height * 0.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Widget'),
        actions: [
          IconButton(
            onPressed: (_isRefreshing || !_calendarGranted) ? null : _refresh,
            tooltip: 'Vernieuwen',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: previewHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CalendarPreviewFrame(
                      settings: settings,
                      data: _data,
                      wallpaperPng: _wallpaperPng,
                      isLoading: _isRefreshing,
                    ),
                  ),
                ),
                Expanded(
                  child: _calendarGranted
                      ? const Center(
                          child: Text(
                            'Instellingen volgen in de volgende stap.',
                          ),
                        )
                      : CalendarPermissionBanner(
                          permanentlyDenied: _permanentlyDenied,
                          onRequest: _requestPermission,
                          onOpenSettings: _openSettings,
                        ),
                ),
              ],
            ),
    );
  }
}
