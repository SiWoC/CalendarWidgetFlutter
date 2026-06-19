import 'package:flutter/material.dart';

/// Shown when calendar access is missing or permanently denied.
class CalendarPermissionBanner extends StatelessWidget {
  const CalendarPermissionBanner({
    super.key,
    required this.permanentlyDenied,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final bool permanentlyDenied;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            permanentlyDenied
                ? 'Kalendertoegang is geweigerd. Sta toegang toe in de app-instellingen.'
                : 'Deze app heeft toegang tot je agenda nodig om afspraken te tonen.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          if (permanentlyDenied)
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open instellingen'),
            )
          else
            FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.check),
              label: const Text('Toestemming geven'),
            ),
        ],
      ),
    );
  }
}
