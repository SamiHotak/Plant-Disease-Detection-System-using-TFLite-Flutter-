import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

/// Explains what the app does and lists every class the model can predict.
///
/// The class list is built from the labels actually loaded from
/// `labels.txt`, not hardcoded, so it stays accurate if the model is retrained
/// on a different set of classes.
class AboutScreen extends StatefulWidget {
  final List<String> labels;

  const AboutScreen({super.key, required this.labels});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Groups `Plant___Disease` labels into { plant: [disease, ...] }.
  Map<String, List<String>> get _grouped {
    final map = <String, List<String>>{};
    for (final raw in widget.labels) {
      final parts = raw.split('___');
      final plant = _pretty(parts.first);
      final disease = _pretty(parts.length > 1 ? parts.last : 'Unknown');
      map.putIfAbsent(plant, () => <String>[]).add(disease);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        // Healthy first, then alphabetical.
        final ah = a.toLowerCase().contains('healthy');
        final bh = b.toLowerCase().contains('healthy');
        if (ah != bh) return ah ? -1 : 1;
        return a.compareTo(b);
      });
    }
    return map;
  }

  Map<String, List<String>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _grouped;

    final out = <String, List<String>>{};
    _grouped.forEach((plant, diseases) {
      if (plant.toLowerCase().contains(q)) {
        out[plant] = diseases;
      } else {
        final hits =
            diseases.where((d) => d.toLowerCase().contains(q)).toList();
        if (hits.isNotEmpty) out[plant] = hits;
      }
    });
    return out;
  }

  static String _pretty(String raw) {
    final s = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _grouped;
    final filtered = _filtered;
    final diseaseCount = widget.labels
        .where((l) => !l.toLowerCase().contains('healthy'))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
          _buildIdentity(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildStats(theme, grouped.length, diseaseCount),
          const SizedBox(height: AppSpacing.lg),
          _buildHowItWorks(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildTips(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildCoverage(theme, grouped, filtered),
          const SizedBox(height: AppSpacing.lg),
          _buildLimitations(theme),
        ],
      ),
    );
  }

  Widget _buildIdentity(ThemeData theme) {
    return Column(
      children: <Widget>[
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: AppColors.primaryA14,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primaryA24),
          ),
          child: const Icon(Icons.eco, color: AppColors.primary, size: 34),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(AppInfo.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(
          '${AppInfo.tagline} · v${AppInfo.version}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppInfo.description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme, int species, int diseases) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _stat(theme, '${widget.labels.length}', 'classes'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _stat(theme, '$species', 'crops')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _stat(theme, '$diseases', 'diseases')),
      ],
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style:
                theme.textTheme.headlineMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('How it works', icon: Icons.route_outlined),
          const SizedBox(height: AppSpacing.md),
          ...List<Widget>.generate(AppInfo.pipelineSteps.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: i == AppInfo.pipelineSteps.length - 1 ? 0 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryA14,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppInfo.pipelineSteps[i],
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryA08,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.primaryA24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Everything runs on your device. No photo is uploaded and '
                    'no connection is required.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('Getting the best results',
              icon: Icons.camera_outlined),
          const SizedBox(height: AppSpacing.md),
          ...AppInfo.captureTips.map(
            (t) => BulletLine(text: t, accent: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverage(
    ThemeData theme,
    Map<String, List<String>> grouped,
    Map<String, List<String>> filtered,
  ) {
    if (widget.labels.isEmpty) {
      return AppCard(
        background: AppColors.dangerA14,
        borderColor: AppColors.dangerA40,
        child: Text(
          'The model is not loaded, so the class list is unavailable. '
          'Check that the model files are present in assets/models/.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final plants = filtered.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionLabel('What it can detect', icon: Icons.spa_outlined),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The model predicts ${widget.labels.length} classes across '
          '${grouped.length} crops. Each crop lists the conditions it can '
          'distinguish, including a healthy state.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search crop or disease',
            hintStyle: theme.textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.search,
                size: 19, color: AppColors.textTertiary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close,
                        size: 17, color: AppColors.textTertiary),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (plants.isEmpty)
          AppCard(
            child: Text(
              'Nothing matches "$_query".',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...plants.map((plant) => _cropCard(theme, plant, filtered[plant]!)),
      ],
    );
  }

  Widget _cropCard(ThemeData theme, String plant, List<String> diseases) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.eco_outlined,
                    size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(plant, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${diseases.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: diseases.map((d) {
                final healthy = d.toLowerCase().contains('healthy');
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: healthy
                        ? AppColors.primaryA08
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color:
                          healthy ? AppColors.primaryA24 : AppColors.border,
                    ),
                  ),
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: healthy
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitations(ThemeData theme) {
    return AppCard(
      background: AppColors.cautionA14,
      borderColor: AppColors.cautionA40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.caution),
              const SizedBox(width: 8),
              Text(
                'Limitations',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.caution),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...AppInfo.limitations.map(
            (t) => BulletLine(text: t, accent: AppColors.caution),
          ),
        ],
      ),
    );
  }
}
