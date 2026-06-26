import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_ext.dart';
import '../utils.dart';
import '../widget_constants.dart';
import '../widget_settings.dart';
import 'color_picker_dialog.dart';

/// Companion-app settings for language, background, and appearance.
class WidgetSettingsPanel extends StatelessWidget {
  const WidgetSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final WidgetSettings settings;
  final ValueChanged<WidgetSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _LanguageTile(
          label: l10n.settingsLanguage,
          l10n: l10n,
          value: settings.locale,
          onChanged: (locale) =>
              onSettingsChanged(settings.copyWith(locale: locale)),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsBackground,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        // Widget card background RGB; opacity is controlled by the slider below.
        _ColorPickerTile(
          label: l10n.settingsBackgroundColor,
          color: Utils.backgroundFill(
            settings.backgroundColor,
            settings.backgroundOpacity,
          ),
          onPick: () async {
            final picked = await showColorPicker(
              context: context,
              initialColor: opaqueColorFromHex(settings.backgroundColor),
            );
            if (picked == null || !context.mounted) return;
            onSettingsChanged(
              settings.copyWith(backgroundColor: opaqueColorToHex(picked)),
            );
          },
        ),
        _IntSliderTile(
          label: l10n.settingsBackgroundOpacity,
          valueLabel: l10n.settingsOpacityValue(settings.backgroundOpacity),
          value: settings.backgroundOpacity,
          min: 0,
          max: 100,
          onChanged: (opacity) => onSettingsChanged(
            settings.copyWith(backgroundOpacity: opacity.round()),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsAppearance,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        // Calendar header, section titles, and time/all-day bullets.
        _ColorPickerTile(
          label: l10n.settingsHeaderColor,
          color: Utils.hexToColor(settings.headerColor),
          onPick: () async {
            final picked = await showColorPicker(
              context: context,
              initialColor: opaqueColorFromHex(settings.headerColor),
            );
            if (picked == null || !context.mounted) return;
            onSettingsChanged(
              settings.copyWith(headerColor: opaqueColorToHex(picked)),
            );
          },
        ),
        _IntSliderTile(
          label: l10n.settingsHeaderFontSize,
          valueLabel: l10n.settingsFontSizeValue(settings.headerFontSize),
          value: settings.headerFontSize,
          min: WidgetConstants.MIN_FONT_SIZE,
          max: WidgetConstants.MAX_FONT_SIZE,
          onChanged: (size) => onSettingsChanged(
            settings.copyWith(headerFontSize: size.round()),
          ),
        ),
        _IntSliderTile(
          label: l10n.settingsEventFontSize,
          valueLabel: l10n.settingsFontSizeValue(settings.eventFontSize),
          value: settings.eventFontSize,
          min: WidgetConstants.MIN_FONT_SIZE,
          max: WidgetConstants.MAX_FONT_SIZE,
          onChanged: (size) => onSettingsChanged(
            settings.copyWith(eventFontSize: size.round()),
          ),
        ),
        _IntSliderTile(
          label: l10n.settingsFetchDays,
          valueLabel: l10n.settingsFetchDaysValue(settings.fetchDays),
          value: settings.fetchDays,
          min: WidgetConstants.MIN_FETCH_DAYS,
          max: WidgetConstants.MAX_FETCH_DAYS,
          onChanged: (days) => onSettingsChanged(
            settings.copyWith(fetchDays: days.round()),
          ),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.l10n,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final AppLocalizations l10n;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButton<String>(
        value: AppLocale.isSupported(value) ? value : AppLocale.defaultTag,
        underline: const SizedBox.shrink(),
        items: [
          for (final locale in AppLocale.supportedTags)
            DropdownMenuItem(
              value: locale,
              child: Text(l10n.labelForLocale(locale)),
            ),
        ],
        onChanged: (locale) {
          if (locale != null) onChanged(locale);
        },
      ),
    );
  }
}

/// Settings row with a label and tappable color swatch; [onPick] opens the picker.
class _ColorPickerTile extends StatelessWidget {
  const _ColorPickerTile({
    required this.label,
    required this.color,
    required this.onPick,
  });

  final String label;
  final Color color;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
        ),
      ),
    );
  }
}

class _IntSliderTile extends StatelessWidget {
  const _IntSliderTile({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final int value;
  final int min;
  final int max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          trailing: Text(valueLabel),
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
