import 'dart:io';

import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../models/prediction.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

/// Shown instead of a diagnosis when the image is judged not to be a leaf.
///
/// Presenting a confident-looking disease name for a photo of a cat is worse
/// than presenting nothing, so this path deliberately withholds the class
/// scores and explains what to do instead.
class RejectedScreen extends StatelessWidget {
  final String imagePath;
  final AnalysisResult analysis;
  final VoidCallback onRetry;

  const RejectedScreen({
    super.key,
    required this.imagePath,
    required this.analysis,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('No plant detected'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceHigh,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 40, color: AppColors.textTertiary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              const StatusChip(
                label: 'NOT ANALYSED',
                color: AppColors.danger,
                background: AppColors.dangerA14,
                icon: Icons.block,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This does not look like a plant leaf',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            analysis.rejectionReason ??
                'The image could not be matched to any plant condition.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionLabel('Why no result was shown',
                    icon: Icons.help_outline),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'The model only knows the crops listed on the About screen. '
                  'It has no category for "something else", so given an '
                  'unfamiliar photo it would still return a disease name — and '
                  'that name would be meaningless. Withholding the result is '
                  'the honest outcome.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionLabel('Try again with',
                    icon: Icons.camera_outlined),
                const SizedBox(height: AppSpacing.md),
                ...AppInfo.captureTips.map(
                  (t) => BulletLine(text: t, accent: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Scan another photo',
            icon: Icons.camera_alt_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDiagnostics(theme),
        ],
      ),
    );
  }

  /// Kept visible because it is genuinely useful when tuning thresholds
  /// during development, and harmless to a normal user.
  Widget _buildDiagnostics(ThemeData theme) {
    final s = analysis.imageStats;
    final m = analysis.softmaxStats;
    return AppCard(
      background: AppColors.surfaceHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('Diagnostics', icon: Icons.analytics_outlined),
          const SizedBox(height: AppSpacing.sm),
          _row(theme, 'Plant-coloured pixels',
              '${(s.greenFraction * 100).toStringAsFixed(0)}%  '
                  '(need ${(ImageStatsThresholds.green * 100).toStringAsFixed(0)}%)'),
          _row(theme, 'Excess-green index',
              '${s.meanExcessGreen.toStringAsFixed(1)}  '
                  '(need ${ImageStatsThresholds.exg.toStringAsFixed(0)})'),
          _row(theme, 'Top probability',
              '${(m.topProbability * 100).toStringAsFixed(1)}%'),
          _row(theme, 'Distribution entropy',
              m.normalisedEntropy.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(k, style: theme.textTheme.bodySmall)),
          Text(v, style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Mirrors the thresholds in ImageStats so the diagnostics card can show
/// what the image needed to reach.
class ImageStatsThresholds {
  ImageStatsThresholds._();
  static const double green = 0.25;
  static const double exg = 15.0;
}
