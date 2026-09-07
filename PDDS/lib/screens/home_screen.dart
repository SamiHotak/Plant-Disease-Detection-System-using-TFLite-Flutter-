import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_info.dart';
import '../models/prediction.dart';
import '../services/classifier_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'about_screen.dart';
import 'rejected_screen.dart';
import 'developer_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ClassifierService _classifier = ClassifierService();
  final ImagePicker _picker = ImagePicker();
  final List<ScanResult> _history = <ScanResult>[];

  bool _loadingModel = true;
  bool _analysing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    try {
      await _classifier.load();
      if (!mounted) return;
      setState(() => _loadingModel = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingModel = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    if (!_classifier.isReady || _analysing) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 92,
      );
      if (picked == null) return;

      setState(() => _analysing = true);

      final stopwatch = Stopwatch()..start();
      final analysis = await _classifier.analyse(File(picked.path), topK: 3);
      stopwatch.stop();

      if (!mounted) return;
      setState(() => _analysing = false);

      // Rejected images never enter the history: showing a disease name for a
      // photo of a car would be worse than showing nothing at all.
      if (analysis.verdict == ScanVerdict.notAPlant) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RejectedScreen(
              imagePath: picked.path,
              analysis: analysis,
              onRetry: () => _scan(source),
            ),
          ),
        );
        return;
      }

      final result = ScanResult(
        imagePath: picked.path,
        predictions: analysis.predictions,
        timestamp: DateTime.now(),
        inferenceMs: stopwatch.elapsedMilliseconds,
        verdict: analysis.verdict,
      );

      setState(() => _history.insert(0, result));

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _analysing = false);
      _showError('Analysis failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _classifier.isReady && !_analysing;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                140,
              ),
              children: <Widget>[
                _buildHeader(theme),
                const SizedBox(height: AppSpacing.xl),
                _buildHero(theme),
                const SizedBox(height: AppSpacing.lg),
                if (_loadError != null) _buildErrorPanel(theme),
                _buildTipsCard(theme),
                if (_history.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Recent scans', icon: Icons.history),
                  const SizedBox(height: AppSpacing.md),
                  ..._history.map(_buildHistoryTile),
                ],
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionBar(ready),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryA14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.primaryA24),
          ),
          child: const Icon(Icons.eco, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AppInfo.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                _loadingModel
                    ? 'Loading model…'
                    : _classifier.isReady
                        ? AppInfo.tagline
                        : 'Model unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_classifier.isReady)
          _navButton(
            icon: Icons.info_outline,
            tooltip: 'About the app',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AboutScreen(labels: _classifier.labels),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        _navButton(
          icon: Icons.person_outline,
          tooltip: 'Developer',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DeveloperScreen()),
          ),
        ),
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 19, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Diagnose plant\ndisease in seconds',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Photograph a single leaf and the model identifies the condition '
          'locally on your device — no internet connection required.',
          style: theme.textTheme.bodyLarge,
        ),
        if (_classifier.isReady) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          const StatusChip(
            label: 'OFFLINE READY',
            color: AppColors.primary,
            background: AppColors.primaryA08,
            icon: Icons.offline_bolt,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        background: AppColors.dangerA14,
        borderColor: AppColors.dangerA40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Model failed to load',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(_loadError ?? '', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check that plant_disease_model.tflite and labels.txt are in '
              'assets/models/ and listed in pubspec.yaml.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme) {
    const tips = <String>[
      'Fill the frame with one leaf',
      'Use bright, even, indirect light',
      'Shoot against a plain background',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionLabel('For best results', icon: Icons.tips_and_updates),
          const SizedBox(height: AppSpacing.md),
          ...tips.map(
            (t) => BulletLine(text: t, accent: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ScanResult result) {
    final theme = Theme.of(context);
    final top = result.top;
    final accent = top.isHealthy ? AppColors.healthy : AppColors.caution;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ResultScreen(result: result)),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.file(
                File(result.imagePath),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.surfaceHigh,
                  child: const Icon(Icons.broken_image_outlined,
                      size: 20, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(top.plant, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    top.disease,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              top.confidencePercent,
              style: theme.textTheme.titleMedium?.copyWith(color: accent),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(bool ready) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x000A0F0D), AppColors.background],
          stops: <double>[0.0, 0.45],
        ),
      ),
      child: _analysing
          ? AppCard(
              background: AppColors.surfaceHigh,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Analysing leaf…',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            )
          : Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: PrimaryButton(
                    label: 'Scan leaf',
                    icon: Icons.camera_alt_outlined,
                    onPressed: ready ? () => _scan(ImageSource.camera) : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: SecondaryButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    onPressed: ready ? () => _scan(ImageSource.gallery) : null,
                  ),
                ),
              ],
            ),
    );
  }
}
