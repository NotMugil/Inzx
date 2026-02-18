import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/design_system/design_system.dart';
import '../providers/providers.dart';
import '../services/playback/playback_data.dart';
import '../services/download_service.dart';
import '../services/album_color_extractor.dart';

/// Audio settings screen with quality selection
class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

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
      backgroundColor: backgroundColor,
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
              accentColor: accentColor,
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
            accentColor: accentColor,
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
            accentColor: accentColor,
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
            accentColor: accentColor,
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
            accentColor: accentColor,
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
            accentColor: accentColor,
            quality: AudioQuality.max,
            currentQuality: currentQuality,
            title: 'Maximum',
            subtitle: 'Highest available (~256 kbps)',
            icon: Iconsax.sound,
            onTap: () => playerService.setAudioQuality(AudioQuality.max),
          ),

          const SizedBox(height: 32),

          Text(
            'Crossfade Transition',
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
            accentColor: accentColor,
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
            accentColor: accentColor,
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
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDark,
    required Color accentColor,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
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
    required Color accentColor,
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
              ? accentColor.withValues(alpha: 0.15)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
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
                    ? accentColor.withValues(alpha: 0.2)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? accentColor
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
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
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
              Icon(Icons.check_circle, color: accentColor)
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
    required Color accentColor,
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
              Icon(Iconsax.archive, color: accentColor, size: 24),
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
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: wifiOnly
                      ? MineColors.contrastTextOn(accentColor)
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
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: !wifiOnly
                      ? MineColors.contrastTextOn(accentColor)
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
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: selected
                      ? MineColors.contrastTextOn(accentColor)
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
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: selected
                      ? MineColors.contrastTextOn(accentColor)
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
    required Color accentColor,
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
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: selected
                      ? MineColors.contrastTextOn(accentColor)
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
    final albumColors = ref.watch(albumColorsProvider);
    final hasAlbumColors = !albumColors.isDefault;
    final accentColor = hasAlbumColors
        ? albumColors.accent
        : colorScheme.primary;

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
            accentColor,
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
            accentColor,
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
            accentColor,
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
            accentColor,
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
            accentColor,
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
    Color accentColor,
    VoidCallback onTap,
  ) {
    final isSelected = quality == current;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected
            ? accentColor
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
