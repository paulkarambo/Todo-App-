import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';

class StartupModal extends StatelessWidget {
  const StartupModal({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PlannerProvider>();

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    size: 36, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'Daily Planner Pro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Optimiere deinen Tag mit Struktur und Fokus.',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _StartupButton(
                label: 'Mit Testdaten starten',
                primary: true,
                onPressed: () async {
                  await provider.seedTestData();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              _StartupButton(
                label: 'Leer starten',
                primary: false,
                onPressed: () async {
                  await provider.startEmpty();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onPressed;

  const _StartupButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? AppColors.accent : AppColors.surface,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: primary ? 8 : 0,
          shadowColor: primary ? AppColors.accent.withOpacity(0.4) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}
