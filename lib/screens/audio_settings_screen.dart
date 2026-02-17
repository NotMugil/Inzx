import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/design_system/design_system.dart';
import '../providers/providers.dart';
import '../services/playback/playback_data.dart';
import '../services/download_service.dart';

/// Audio settings screen with quality selection
class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final currentQuality = ref.watch(audioQualityProvider);
    final streamInfo = ref.watch(streamQualityInfoProvider);
    final streamCacheWifiOnly = ref.watch(streamCacheWifiOnlyProvider);
    final streamCacheLimitMb = ref.watch(streamCacheSizeLimitMbProvider);
    final streamCacheMaxConcurrent = ref.watch(
      streamCacheMaxConcurrentProvider,
    );
    final crossfadeDurationMs = ref.watch(crossfadeDurationMsProvider);
    final streamCacheUsageAsync = ref.watch(streamAudioCacheUsageBytesProvider);
    final playerService = ref.watch(audioPlayerServiceProvider);

    return Scaffold(
      backgroundColor: isDark
          ? MineColors.darkBackground
          : MineColors.background,
      appBar: AppBar(
        title: const Text('Audio Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current quality info
          if (streamInfo.isNotEmpty)
            _buildInfoCard(
              context,
              isDark: isDark,
              colorScheme: colorScheme,
              title: 'Now Playing',
              subtitle: streamInfo,
              icon: Iconsax.music_circle,
            ),

          const SizedBox(height: 24),

          // Quality section header
          Text(
            'Streaming Quality',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Higher quality uses more data',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Quality options
          _buildQualityOption(
            context,
            ref: ref,
            isDark: isDark,
            colorScheme: colorScheme,
            quality: AudioQuality.auto,
            currentQuality: currentQuality,
            title: 'Auto',
            subtitle: 'Adjusts based on network speed',
            icon: Iconsax.autobrightness,
            onTap: () => playerService.setAudioQuality(AudioQuality.auto),
          ),

          _buildQualityOption(
            context,
            ref: ref,
            isDark: isDark,
            colorScheme: colorScheme,
            quality: AudioQuality.low,
            currentQuality: currentQuality,
            title: 'Low',
            subtitle: '~64 kbps • Uses less data',
            icon: Iconsax.volume_low,
            onTap: () => playerService.setAudioQuality(AudioQuality.low),
          ),

          _buildQualityOption(
            context,
            ref: ref,
            isDark: isDark,
            colorScheme: colorScheme,
            quality: AudioQuality.medium,
            currentQuality: currentQuality,
            title: 'Medium',
            subtitle: '~128 kbps • Balanced',
            icon: Iconsax.volume_high,
            onTap: () => playerService.setAudioQuality(AudioQuality.medium),
          ),

          _buildQualityOption(
            context,
            ref: ref,
            isDark: isDark,
            colorScheme: colorScheme,
            quality: AudioQuality.high,
            currentQuality: currentQuality,
            title: 'High',
            subtitle: '~256 kbps • Best for most',
            icon: Iconsax.headphones,
            recommended: true,
            onTap: () => playerService.setAudioQuality(AudioQuality.high),
          ),

          _buildQualityOption(
            context,
            ref: ref,
            isDark: isDark,
            colorScheme: colorScheme,
            quality: AudioQuality.max,
            currentQuality: currentQuality,
            title: 'Maximum',
            subtitle: 'Highest available (~256 kbps)',
            icon: Iconsax.sound,
            onTap: () => playerService.setAudioQuality(AudioQuality.max),
          ),

          const SizedBox(height: 32),

          Text(
            'Playback Transition',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Blend the end of the current track into the start of the next',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildCrossfadeSection(
            isDark: isDark,
            colorScheme: colorScheme,
            currentDurationMs: crossfadeDurationMs,
            onChanged: (value) async {
              await playerService.setCrossfadeDurationMs(value);
            },
          ),

          const SizedBox(height: 32),

          // Streaming cache section
          Text(
            'Streaming Cache',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pre-caches next tracks and plays from local cache when available',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStreamingCacheSection(
            context,
            ref: ref,
            isDark: isDark,
            colorScheme: colorScheme,
            wifiOnly: streamCacheWifiOnly,
            cacheLimitMb: streamCacheLimitMb,
            maxConcurrent: streamCacheMaxConcurrent,
            usageAsync: streamCacheUsageAsync,
            onWifiOnlyChanged: (enabled) async {
              await playerService.setStreamCacheWifiOnly(enabled);
              ref.read(streamAudioCacheRefreshProvider.notifier).state++;
            },
            onCacheLimitChanged: (limitMb) async {
              await playerService.setStreamCacheSizeLimitMb(limitMb);
              ref.read(streamAudioCacheRefreshProvider.notifier).state++;
            },
            onMaxConcurrentChanged: (value) async {
              await playerService.setStreamCacheMaxConcurrent(value);
            },
          ),

          const SizedBox(height: 32),

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
          _DownloadQualitySetting(isDark: isDark, colorScheme: colorScheme),

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

          _DownloadPathSetting(isDark: isDark, colorScheme: colorScheme),

          const SizedBox(height: 32),
          // Data usage info
          _buildDataUsageInfo(isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDark,
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : MineColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : MineColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(
    BuildContext context, {
    required WidgetRef ref,
    required bool isDark,
    required ColorScheme colorScheme,
    required AudioQuality quality,
    required AudioQuality currentQuality,
    required String title,
    required String subtitle,
    required IconData icon,
    bool recommended = false,
    required VoidCallback onTap,
  }) {
    final isSelected = quality == currentQuality;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : isDark
                ? Colors.white12
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : MineColors.textPrimary,
                        ),
                      ),
                      if (recommended)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : MineColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary)
            else
              Icon(
                Icons.circle_outlined,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingCacheSection(
    BuildContext context, {
    required WidgetRef ref,
    required bool isDark,
    required ColorScheme colorScheme,
    required bool wifiOnly,
    required int cacheLimitMb,
    required int maxConcurrent,
    required AsyncValue<int> usageAsync,
    required Future<void> Function(bool enabled) onWifiOnlyChanged,
    required Future<void> Function(int limitMb) onCacheLimitChanged,
    required Future<void> Function(int value) onMaxConcurrentChanged,
  }) {
    const cacheLimitOptions = [256, 512, 1024, 2048, 4096];
    const concurrencyOptions = [1, 2, 3, 4];

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
              Icon(Iconsax.archive, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Stream Cache',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : MineColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    usageAsync.when(
                      data: (bytes) => Text(
                        'Used: ${_formatCacheSize(bytes)} / $cacheLimitMb MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : MineColors.textSecondary,
                        ),
                      ),
                      loading: () => Text(
                        'Calculating cache usage...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : MineColors.textSecondary,
                        ),
                      ),
                      error: (error, stackTrace) => Text(
                        'Unable to read cache usage',
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
          const SizedBox(height: 16),
          Text(
            'Pre-cache Network',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: wifiOnly,
                label: const Text('Wi-Fi only'),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: wifiOnly
                      ? colorScheme.onPrimary
                      : (isDark ? Colors.white : MineColors.textPrimary),
                ),
                onSelected: (picked) {
                  if (picked) {
                    onWifiOnlyChanged(true);
                  }
                },
              ),
              ChoiceChip(
                selected: !wifiOnly,
                label: const Text('Wi-Fi + mobile data'),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: !wifiOnly
                      ? colorScheme.onPrimary
                      : (isDark ? Colors.white : MineColors.textPrimary),
                ),
                onSelected: (picked) {
                  if (picked) {
                    onWifiOnlyChanged(false);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wifiOnly
                ? 'Pre-cache runs only when connected to Wi-Fi'
                : 'Pre-cache can run on both Wi-Fi and mobile data',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Concurrent Pre-cache Downloads',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: concurrencyOptions.map((option) {
              final selected = option == maxConcurrent;
              return ChoiceChip(
                selected: selected,
                label: Text('$option'),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.onPrimary
                      : (isDark ? Colors.white : MineColors.textPrimary),
                ),
                onSelected: (picked) {
                  if (picked) {
                    onMaxConcurrentChanged(option);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Higher values cache faster but use more network and battery',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cache Size Limit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : MineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cacheLimitOptions.map((optionMb) {
              final selected = optionMb == cacheLimitMb;
              return ChoiceChip(
                selected: selected,
                label: Text('$optionMb MB'),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.onPrimary
                      : (isDark ? Colors.white : MineColors.textPrimary),
                ),
                onSelected: (picked) {
                  if (picked) {
                    onCacheLimitChanged(optionMb);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossfadeSection({
    required bool isDark,
    required ColorScheme colorScheme,
    required int currentDurationMs,
    required Future<void> Function(int value) onChanged,
  }) {
    const optionsMs = [0, 1000, 2000, 3000, 5000, 8000];

    String labelFor(int ms) {
      if (ms == 0) return 'Off';
      return '${(ms / 1000).toStringAsFixed(ms % 1000 == 0 ? 0 : 1)}s';
    }

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: optionsMs.map((optionMs) {
              final selected = optionMs == currentDurationMs;
              return ChoiceChip(
                selected: selected,
                label: Text(labelFor(optionMs)),
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.onPrimary
                      : (isDark ? Colors.white : MineColors.textPrimary),
                ),
                onSelected: (picked) {
                  if (picked) {
                    onChanged(optionMs);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            currentDurationMs == 0
                ? 'Crossfade disabled'
                : 'Current: ${labelFor(currentDurationMs)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : MineColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCacheSize(int bytes) {
    const mb = 1024 * 1024;
    if (bytes <= 0) return '0 MB';
    return '${(bytes / mb).toStringAsFixed(1)} MB';
  }

  Widget _buildDataUsageInfo(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
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
                'Estimated Data Usage',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : MineColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataRow('Low', '~3 MB per song', isDark),
          _buildDataRow('Medium', '~6 MB per song', isDark),
          _buildDataRow('High', '~12 MB per song', isDark),
          _buildDataRow('Lossless', '~25+ MB per song', isDark),
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

/// Quick quality picker for Now Playing screen
class AudioQualityPicker extends ConsumerWidget {
  const AudioQualityPicker({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AudioQualityPicker(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final currentQuality = ref.watch(audioQualityProvider);
    final playerService = ref.watch(audioPlayerServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white30 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Audio Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : MineColors.textPrimary,
              ),
            ),
          ),

          const Divider(height: 1),

          _buildQuickOption(
            context,
            'Auto',
            AudioQuality.auto,
            currentQuality,
            isDark,
            colorScheme,
            () {
              playerService.setAudioQuality(AudioQuality.auto);
              Navigator.pop(context);
            },
          ),
          _buildQuickOption(
            context,
            'Low (64 kbps)',
            AudioQuality.low,
            currentQuality,
            isDark,
            colorScheme,
            () {
              playerService.setAudioQuality(AudioQuality.low);
              Navigator.pop(context);
            },
          ),
          _buildQuickOption(
            context,
            'Medium (128 kbps)',
            AudioQuality.medium,
            currentQuality,
            isDark,
            colorScheme,
            () {
              playerService.setAudioQuality(AudioQuality.medium);
              Navigator.pop(context);
            },
          ),
          _buildQuickOption(
            context,
            'High (256 kbps)',
            AudioQuality.high,
            currentQuality,
            isDark,
            colorScheme,
            () {
              playerService.setAudioQuality(AudioQuality.high);
              Navigator.pop(context);
            },
          ),
          _buildQuickOption(
            context,
            'Maximum (~256 kbps)',
            AudioQuality.max,
            currentQuality,
            isDark,
            colorScheme,
            () {
              playerService.setAudioQuality(AudioQuality.max);
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickOption(
    BuildContext context,
    String title,
    AudioQuality quality,
    AudioQuality current,
    bool isDark,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    final isSelected = quality == current;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected
            ? colorScheme.primary
            : (isDark ? Colors.white38 : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : MineColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Download quality setting widget
class _DownloadQualitySetting extends ConsumerWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _DownloadQualitySetting({
    required this.isDark,
    required this.colorScheme,
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
              Icon(
                Iconsax.document_download,
                color: colorScheme.primary,
                size: 24,
              ),
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
                  ? colorScheme.onPrimary.withValues(alpha: 0.8)
                  : (isDark ? Colors.white54 : Colors.grey),
            ),
          ),
        ],
      ),
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimary
            : (isDark ? Colors.white : Colors.black87),
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(downloadQualityProvider.notifier).setQuality(quality);
          // Also update the download manager
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
  final ColorScheme colorScheme;

  const _DownloadPathSetting({required this.isDark, required this.colorScheme});

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
              Icon(Iconsax.folder_2, color: colorScheme.primary, size: 24),
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
