import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/design_system.dart';
import '../../providers/providers.dart';
import '../../services/download_service.dart';

/// Download indicator widget for mini player
class _DownloadIndicator extends ConsumerWidget {
  final String trackId;
  final Color color;

  const _DownloadIndicator({required this.trackId, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded = ref.watch(isTrackDownloadedProvider(trackId));
    final progress = ref.watch(trackDownloadProgressProvider(trackId));

    if (isDownloaded) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(Iconsax.tick_circle5, size: 14, color: Colors.green),
      );
    }

    if (progress != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 1.5,
            color: color,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Progress bar that updates on position changes only (isolated rebuild)
class _MiniPlayerProgress extends ConsumerWidget {
  final Duration? duration;
  final Color backgroundColor;
  final Color progressColor;

  const _MiniPlayerProgress({
    required this.duration,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;

    // No border radius - connects seamlessly to nav bar below
    return LinearProgressIndicator(
      value: (duration?.inMilliseconds ?? 0) > 0
          ? position.inMilliseconds / duration!.inMilliseconds
          : 0,
      backgroundColor: backgroundColor,
      valueColor: AlwaysStoppedAnimation(progressColor),
      minHeight: 3,
    );
  }
}

/// Mini player widget that shows above the bottom nav
class MusicMiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;

  const MusicMiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final playbackState = ref.watch(playbackStateProvider);
    final playerService = ref.watch(audioPlayerServiceProvider);
    final albumColors = ref.watch(albumColorsProvider);

    return playbackState.when(
      data: (state) {
        if (state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;

        // Use album colors if not default, otherwise fall back to theme
        final hasAlbumColors = !albumColors.isDefault;

        // Accent for progress bar
        final accentColor = hasAlbumColors
            ? albumColors.accent
            : colorScheme.primary;

        // Background gradient - use album tint in light mode when dynamic colors are active
        final List<Color> gradientColors;
        final Color borderColor;
        Color backgroundForText; // Used to compute adaptive text colors

        if (isDark) {
          if (hasAlbumColors) {
            // Dark mode with album colors - subtle album tint
            gradientColors = [
              albumColors.backgroundPrimary.withValues(alpha: 0.9),
              albumColors.backgroundSecondary.withValues(alpha: 0.85),
            ];
            borderColor = albumColors.accent.withValues(alpha: 0.2);
            backgroundForText = albumColors.backgroundPrimary;
          } else {
            gradientColors = [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.05),
            ];
            backgroundForText = MineColors.darkBackground;
            borderColor = Colors.white.withValues(alpha: 0.15);
          }
        } else {
          // Light mode - always use white/glass, no album tint
          gradientColors = [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.65),
          ];
          borderColor = hasAlbumColors
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.8);
          backgroundForText = MineColors.background;
        }

        // Adaptive text colors based on background luminance
        final textColors = MineColors.adaptiveTextColors(backgroundForText);
        final foregroundColor = textColors.primary;
        final secondaryColor = textColors.secondary;

        return GestureDetector(
          onTap: onTap,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                // Full width glassmorphism design matching nav bar
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  border: Border(
                    top: BorderSide(color: borderColor, width: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Content first
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 4, 10),
                      child: Row(
                        children: [
                          // Album art with Hero for smooth transition
                          Hero(
                            tag: 'album-art-${track.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: track.thumbnailUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: track.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            _defaultArt(colorScheme),
                                        errorWidget: (_, __, ___) =>
                                            _defaultArt(colorScheme),
                                      )
                                    : _defaultArt(colorScheme),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Track info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: foregroundColor,
                                        ),
                                      ),
                                    ),
                                    // Download indicator - positioned after title
                                    _DownloadIndicator(
                                      trackId: track.id,
                                      color: secondaryColor,
                                    ),
                                  ],
                                ),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: playerService.skipToPrevious,
                                icon: Icon(
                                  Iconsax.previous,
                                  color: foregroundColor,
                                  size: 22,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                onPressed: state.isPlaying
                                    ? playerService.pause
                                    : playerService.play,
                                icon: Icon(
                                  state.isPlaying
                                      ? Iconsax.pause
                                      : Iconsax.play,
                                  color: foregroundColor,
                                  size: 26,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                onPressed: playerService.skipToNext,
                                icon: Icon(
                                  Iconsax.next,
                                  color: foregroundColor,
                                  size: 22,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Progress bar at bottom - connects to nav bar
                    _MiniPlayerProgress(
                      duration: state.duration,
                      backgroundColor: foregroundColor.withValues(alpha: 0.15),
                      progressColor: accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _defaultArt(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Icon(Iconsax.music, color: colorScheme.primary, size: 24),
    );
  }
}
