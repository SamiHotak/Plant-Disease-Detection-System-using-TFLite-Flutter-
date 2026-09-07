import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_info.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer'),
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
          _buildProfile(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildContact(context, theme),
          const SizedBox(height: AppSpacing.lg),
          _buildAbout(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildTechStack(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildDataset(theme),
          const SizedBox(height: AppSpacing.lg),
          _buildHowBuilt(theme),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ profile
  Widget _buildProfile(ThemeData theme) {
    return Column(
      children: <Widget>[
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryA40, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              DeveloperInfo.photoAsset,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              // Falls back to initials when no photo is bundled, so the
              // screen renders correctly before you add your own image.
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryA14,
                alignment: Alignment.center,
                child: Text(
                  DeveloperInfo.initials,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          DeveloperInfo.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          DeveloperInfo.role,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.school_outlined,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                DeveloperInfo.organisation,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.place_outlined,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                DeveloperInfo.location,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ contact
  Widget _buildContact(BuildContext context, ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('Contact', icon: Icons.contact_page_outlined),
          const SizedBox(height: AppSpacing.md),
          _contactRow(
            context,
            theme,
            Icons.phone_outlined,
            'Phone',
            DeveloperInfo.phone,
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          _contactRow(
            context,
            theme,
            Icons.mail_outline,
            'Email',
            DeveloperInfo.email,
          ),
          if (DeveloperInfo.website.isNotEmpty) ...<Widget>[
            const Divider(height: AppSpacing.lg, color: AppColors.border),
            _contactRow(
              context,
              theme,
              Icons.language,
              'Website',
              DeveloperInfo.website,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap any row to copy it to the clipboard.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Copying to the clipboard rather than launching the dialer or mail client
  /// keeps the app free of the `url_launcher` dependency and its extra
  /// Android/iOS manifest configuration.
  Widget _contactRow(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied'),
            backgroundColor: AppColors.surfaceHigh,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryA08,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const Icon(Icons.copy_outlined,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- about
  Widget _buildAbout(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('About the developer',
              icon: Icons.person_outline),
          const SizedBox(height: AppSpacing.md),
          Text(DeveloperInfo.bio, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- tech stack
  Widget _buildTechStack(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _techGroup(
          theme,
          'Machine learning',
          Icons.psychology_outlined,
          TechStack.ml,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        _techGroup(
          theme,
          'Mobile application',
          Icons.phone_android_outlined,
          TechStack.app,
          AppColors.caution,
        ),
      ],
    );
  }

  Widget _techGroup(
    ThemeData theme,
    String title,
    IconData icon,
    List<TechItem> items,
    Color accent,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(title, icon: icon),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 5,
                    height: 5,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(t.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 1),
                        Text(t.role, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ dataset
  Widget _buildDataset(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('Training dataset', icon: Icons.dataset_outlined),
          const SizedBox(height: AppSpacing.md),
          Text(DatasetInfo.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(DatasetInfo.source, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _statTile(
                  theme,
                  _formatNumber(DatasetInfo.totalImages),
                  'total images',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _statTile(
                  theme,
                  '${DatasetInfo.totalClasses}',
                  'classes',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _statTile(
                  theme,
                  '${DatasetInfo.totalSpecies}',
                  'crop species',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(DatasetInfo.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _kv(theme, 'Images used for training',
              '~${_formatNumber(DatasetInfo.imagesUsed)}'),
          _kv(theme, 'Cap per class',
              '${DatasetInfo.imagesPerClassCap} images'),
          _kv(theme, 'Train / validation split',
              '${DatasetInfo.trainSplitPercent}% / '
                  '${DatasetInfo.valSplitPercent}%'),
          _kv(theme, 'Validation accuracy', DatasetInfo.reportedAccuracy),
          _kv(theme, 'Licence', DatasetInfo.licence),
          const SizedBox(height: AppSpacing.sm),
          Text(DatasetInfo.preprocessing, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _statTile(ThemeData theme, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: <Widget>[
          FittedBox(
            child: Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _kv(ThemeData theme, String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(key, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- how built
  Widget _buildHowBuilt(ThemeData theme) {
    const stages = <List<String>>[
      <String>[
        'Data preparation',
        'Catalogued every image with Pandas, checked class balance, removed '
            'unreadable files, then split the set with scikit-learn using '
            'stratification.',
      ],
      <String>[
        'Model training',
        'MobileNetV2 pretrained on ImageNet. Phase one trained only the new '
            'classifier head with the backbone frozen; phase two unfroze the '
            'top 40 layers at a much lower learning rate.',
      ],
      <String>[
        'Evaluation',
        'Measured with a scikit-learn classification report, a normalised '
            'confusion matrix, and a per-class accuracy breakdown to expose '
            'weak classes.',
      ],
      <String>[
        'Mobile export',
        'Converted to TensorFlow Lite with float16 quantization, reducing the '
            'model to roughly 5 MB, then verified the converted model still '
            'matched the original predictions.',
      ],
      <String>[
        'Application',
        'Flutter app running the model through tflite_flutter. Image decoding '
            'happens in a background isolate so the interface stays responsive '
            'during analysis.',
      ],
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('How it was built',
              icon: Icons.construction_outlined),
          const SizedBox(height: AppSpacing.md),
          ...List<Widget>.generate(stages.length, (i) {
            final isLast = i == stages.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryA14,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryA40),
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
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(stages[i][0],
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(stages[i][1],
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
