import 'dart:io';

import 'package:flutter/material.dart';

import '../data/disease_library.dart';
import '../models/prediction.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/confidence_ring.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = result.top;
    final info = DiseaseLibrary.lookup(top.rawLabel);
    final accent = AppColors.forSeverity(info.severity);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          _buildImageHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (result.verdict == ScanVerdict.uncertain) ...<Widget>[
                    _buildUncertainBanner(theme),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _buildVerdict(theme, top, info, accent),
                  const SizedBox(height: AppSpacing.lg),
                  _buildConfidenceCard(theme, top, accent),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAlternatives(theme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildGuidance(info, accent),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDisclaimer(theme),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the image passed the plant check but the model was not
  /// confident. The result is still displayed, framed as a possibility.
  Widget _buildUncertainBanner(ThemeData theme) {
    return AppCard(
      background: AppColors.cautionA14,
      borderColor: AppColors.cautionA40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.caution),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Treat this as a possibility, not a diagnosis',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.caution),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence was low or two conditions scored closely. '
                  'Retake the photo with a single leaf filling the frame in '
                  'even light.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: AppColors.blackA60,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.file(
              File(result.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceHigh,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColors.blackA40,
                    Color(0x000A0F0D),
                    AppColors.background,
                  ],
                  stops: <double>[0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdict(
    ThemeData theme,
    Prediction top,
    DiseaseInfo info,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            StatusChip(
              label: top.isHealthy ? 'HEALTHY' : 'DISEASE DETECTED',
              color: accent,
              background: top.isHealthy
                  ? AppColors.primaryA08
                  : AppColors.cautionA14,
              icon: top.isHealthy
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
            ),
            const Spacer(),
            Text(
              '${result.inferenceMs} ms',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(top.plant.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 6),
        Text(info.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(info.summary, style: theme.textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildConfidenceCard(
    ThemeData theme,
    Prediction top,
    Color accent,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          ConfidenceRing(
            value: top.confidence,
            color: accent,
            caption: 'confidence',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            top.level.label,
            style: theme.textTheme.titleMedium?.copyWith(color: accent),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              top.level.advice,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatives(ThemeData theme) {
    final others = result.predictions.skip(1).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionLabel('Other possibilities', icon: Icons.layers_outlined),
        const SizedBox(height: AppSpacing.md),
        ...others.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(p.disease, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(p.plant, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          p.confidencePercent,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: p.confidence.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGuidance(DiseaseInfo info, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _guidanceBlock(
          'What to look for',
          Icons.visibility_outlined,
          info.symptoms,
          accent,
        ),
        const SizedBox(height: AppSpacing.md),
        _guidanceBlock(
          'Treatment',
          Icons.healing_outlined,
          info.treatment,
          accent,
        ),
        const SizedBox(height: AppSpacing.md),
        _guidanceBlock(
          'Prevention',
          Icons.shield_outlined,
          info.prevention,
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _guidanceBlock(
    String title,
    IconData icon,
    List<String> items,
    Color accent,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(title, icon: icon),
          const SizedBox(height: AppSpacing.md),
          ...items.map((t) => BulletLine(text: t, accent: accent)),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ThemeData theme) {
    return AppCard(
      background: AppColors.surfaceHigh,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is an automated estimate from a model trained on the '
              'PlantVillage dataset. Confirm with a qualified agronomist '
              'before applying chemical treatments.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
