import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'calendar_permission.dart';
import 'calendar_platform_channel.dart';
import 'calendar_widget_data.dart';
import 'l10n/app_localizations.dart';
import 'widget_settings.dart';
import 'widgets/calendar_permission_banner.dart';
import 'widgets/calendar_preview_frame.dart';
import 'widgets/widget_settings_panel.dart';

void main() {
  runApp(const CalendarWidgetApp());
}

class CalendarWidgetApp extends StatefulWidget {
  const CalendarWidgetApp({super.key});

  @override
  State<CalendarWidgetApp> createState() => _CalendarWidgetAppState();
}

class _CalendarWidgetAppState extends State<CalendarWidgetApp> {
  WidgetSettings? _settings;

  @override
  void initState() {
    super.initState();
    WidgetSettings.load().then((settings) {
      if (!mounted) return;
      setState(() => _settings = settings);
    });
  }

  void _replaceSettings(WidgetSettings settings) {
    setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    if (settings == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: lookupAppLocalizations(settings.appLocale).appTitle,
      locale: settings.appLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: CalendarHomePage(
        settings: settings,
        onSettingsChanged: _replaceSettings,
      ),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final WidgetSettings settings;
  final ValueChanged<WidgetSettings> onSettingsChanged;

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage>
    with WidgetsBindingObserver {
  CalendarWidgetData? _data;
  bool _isRefreshing = false;
  bool _calendarGranted = false;
  bool _permanentlyDenied = false;
  Uint8List? _wallpaperPng;
  Timer? _backgroundWidgetUpdateDebounce;

  WidgetSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialState();
  }

  @override
  void dispose() {
    _backgroundWidgetUpdateDebounce?.cancel();
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
    final cached = await CalendarWidgetData.loadFromPrefs();
    if (!mounted) return;
    setState(() => _data = cached);
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
      _showSnackBar(
        AppLocalizations.of(context)!.refreshFailed(
          error.message ?? error.code,
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      _showSnackBar(error.message);
    }
  }

  Future<void> _handleSettingsChanged(WidgetSettings updated) async {
    final previous = _settings;

    widget.onSettingsChanged(updated);
    await updated.save();
    if (!mounted) return;

    final refreshNeeded =
        previous.locale != updated.locale ||
        previous.headerColor != updated.headerColor ||
        previous.headerFontSize != updated.headerFontSize ||
        previous.eventFontSize != updated.eventFontSize ||
        previous.fetchDays != updated.fetchDays;
    final widgetUpdateNeeded =
        previous.backgroundColor != updated.backgroundColor ||
        previous.backgroundOpacity != updated.backgroundOpacity;

    debugPrint(
      'handleSettingsChanged: refreshNeeded=$refreshNeeded, '
      'widgetUpdateNeeded=$widgetUpdateNeeded',
    );

    if (refreshNeeded && _calendarGranted) {
      await _refresh();
    } else if (widgetUpdateNeeded) {
      _scheduleBackgroundWidgetUpdate();
    }
  }

  void _scheduleBackgroundWidgetUpdate() {
    _backgroundWidgetUpdateDebounce?.cancel();
    _backgroundWidgetUpdateDebounce = Timer(
      const Duration(milliseconds: 300),
      () async {
        if (!mounted) return;
        try {
          await CalendarPlatformChannel.updateWidget();
        } on PlatformException catch (error) {
          debugPrint(
            'updateWidget failed: code=${error.code}, message=${error.message}',
          );
        }
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = MediaQuery.sizeOf(context).height * 0.5;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: (_isRefreshing || !_calendarGranted) ? null : _refresh,
            tooltip: l10n.actionRefresh,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: previewHeight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CalendarPreviewFrame(
                settings: _settings,
                data: _data,
                wallpaperPng: _wallpaperPng,
                isLoading: _isRefreshing,
              ),
            ),
          ),
          Expanded(
            child: _calendarGranted
                ? WidgetSettingsPanel(
                    settings: _settings,
                    onSettingsChanged: _handleSettingsChanged,
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
