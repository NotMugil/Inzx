import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/design_system/design_system.dart';
import '../providers/providers.dart';
import '../services/playback/playback_data.dart';
import '../services/download_service.dart';

/// Download settings screen — quality, location, and data usage
class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final albumColors = ref.watch(albumColorsProvider);
    final hasAlbumColors = !albumColors.isDefault;

    // Dynamic colors - plain white background in light mode
    final backgroundColor = (hasAlbumColors && isDark)
        ? albumColors.backgroundSecondary
        : (isDark ? MineColors.darkBackground : MineColors.background);
    final accentColor = hasAlbumColors
        ? albumColors.accent
        : colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Download Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Download quality section
          Text(
            'Download Quality',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quality for offline downloads',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Download quality selector
          _DownloadQualitySetting(isDark: isDark, accentColor: accentColor),

          const SizedBox(height: 32),

          // Download Location section
          Text(
            'Download Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where downloaded music files are stored',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          _DownloadPathSetting(isDark: isDark, accentColor: accentColor),

          const SizedBox(height: 32),

          // Data usage info
          _buildDataUsageInfo(isDark, accentColor),

          const SizedBox(height: 32),

          // Tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Iconsax.lamp_charge, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Downloaded tracks play without internet and don\'t use streaming data.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : MineColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataUsageInfo(bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                size: 18,
                color: isDark ? Colors.white54 : MineColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated Storage per Song',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : MineColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataRow('Low', '~3 MB', isDark),
          _buildDataRow('Medium', '~6 MB', isDark),
          _buildDataRow('High', '~12 MB', isDark),
          _buildDataRow('Max', '~25+ MB', isDark),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : MineColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Download quality setting widget
class _DownloadQualitySetting extends ConsumerWidget {
  final bool isDark;
  final Color accentColor;

  const _DownloadQualitySetting({
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadQuality = ref.watch(downloadQualityProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.document_download, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Quality',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : MineColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getQualityDescription(downloadQuality),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : MineColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quality options as chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQualityChip(
                context,
                ref,
                AudioQuality.low,
                'Low',
                '~64 kbps',
                downloadQuality,
              ),
              _buildQualityChip(
                context,
                ref,
                AudioQuality.medium,
                'Medium',
                '~128 kbps',
                downloadQuality,
              ),
              _buildQualityChip(
                context,
                ref,
                AudioQuality.high,
                'High',
                '~256 kbps',
                downloadQuality,
              ),
              _buildQualityChip(
                context,
                ref,
                AudioQuality.max,
                'Max',
                'Highest',
                downloadQuality,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getQualityDescription(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.auto:
        return 'Auto - Adapts to network';
      case AudioQuality.low:
        return 'Low - ~64 kbps (saves storage)';
      case AudioQuality.medium:
        return 'Medium - ~128 kbps (balanced)';
      case AudioQuality.high:
        return 'High - ~256 kbps (recommended)';
      case AudioQuality.max:
        return 'Maximum - Highest available (~256 kbps)';
    }
  }

  Widget _buildQualityChip(
    BuildContext context,
    WidgetRef ref,
    AudioQuality quality,
    String label,
    String subtitle,
    AudioQuality currentQuality,
  ) {
    final isSelected = quality == currentQuality;

    return FilterChip(
      selected: isSelected,
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? MineColors.contrastTextOn(
                      accentColor,
                    ).withValues(alpha: 0.8)
                  : (isDark ? Colors.white54 : Colors.grey),
            ),
          ),
        ],
      ),
      selectedColor: accentColor,
      checkmarkColor: MineColors.contrastTextOn(accentColor),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected
            ? MineColors.contrastTextOn(accentColor)
            : (isDark ? Colors.white : Colors.black87),
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(downloadQualityProvider.notifier).setQuality(quality);
          ref
              .read(downloadManagerProvider.notifier)
              .setDownloadQuality(quality);
        }
      },
    );
  }
}

/// Download path setting widget
class _DownloadPathSetting extends ConsumerWidget {
  final bool isDark;
  final Color accentColor;

  const _DownloadPathSetting({required this.isDark, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadPathAsync = ref.watch(downloadPathProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.folder_2, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Location',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : MineColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    downloadPathAsync.when(
                      data: (path) => Text(
                        path,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : MineColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : MineColors.textSecondary,
                        ),
                      ),
                      error: (error, stackTrace) => Text(
                        'Error loading path',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Downloads are stored in app-private storage for better reliability and no permission requirements.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : MineColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
