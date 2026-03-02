import 'package:flutter/services.dart';
import '../models/models.dart';
import 'audio_player_service.dart' as player;

/// Syncs playback metadata to the native Android home-screen widget.
class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel('inzx/widget');

  static String? _lastFingerprint;
  static String? _lastProgressFingerprint;

  static Future<void> syncPlaybackState(player.PlaybackState state) async {
    final track = state.currentTrack;
    final hasTrack = track != null;

    final payload = <String, dynamic>{
      'trackId': track?.id,
      'title': track?.title ?? 'Not playing',
      'artist': track?.artist ?? 'Open Inzx to start music',
      'isPlaying': state.isPlaying,
      'hasTrack': hasTrack,
      'positionMs': state.position.inMilliseconds,
      'durationMs': (state.duration ?? Duration.zero).inMilliseconds,
    };

    final fingerprint = _fingerprintFrom(track, state.isPlaying, hasTrack);
    if (_lastFingerprint == fingerprint) return;
    _lastFingerprint = fingerprint;

    try {
      await _channel.invokeMethod('syncPlaybackState', payload);
    } catch (_) {
      // Widget sync is best-effort and should never block playback controls.
    }
  }

  static Future<void> syncProgress({
    required Track? track,
    required bool isPlaying,
    required bool hasTrack,
    required Duration position,
    required Duration? duration,
  }) async {
    if (!hasTrack) return;

    // Widget progress updates are throttled to 1-second buckets.
    final secondBucket = position.inSeconds;
    final durationMs = (duration ?? Duration.zero).inMilliseconds;
    final progressFingerprint =
        '${track?.id ?? ''}|$secondBucket|$durationMs|$isPlaying';
    if (_lastProgressFingerprint == progressFingerprint) return;
    _lastProgressFingerprint = progressFingerprint;

    final payload = <String, dynamic>{
      'positionMs': position.inMilliseconds,
      'durationMs': durationMs,
      'hasTrack': hasTrack,
      'isPlaying': isPlaying,
    };

    try {
      await _channel.invokeMethod('syncPlaybackState', payload);
    } catch (_) {
      // Widget sync is best-effort and should never block playback controls.
    }
  }

  static String _fingerprintFrom(Track? track, bool isPlaying, bool hasTrack) {
    final id = track?.id ?? '';
    final title = track?.title ?? '';
    final artist = track?.artist ?? '';
    return '$id|$title|$artist|$isPlaying|$hasTrack';
  }
}
