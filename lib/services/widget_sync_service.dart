import 'package:flutter/services.dart';
import '../models/models.dart';
import 'audio_player_service.dart' as player;

/// Syncs playback metadata to the native Android home-screen widget.
class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel('inzx/widget');

  static String? _lastFingerprint;

  static Future<void> syncPlaybackState(player.PlaybackState state) async {
    final track = state.currentTrack;
    final hasTrack = track != null;

    final payload = <String, dynamic>{
      'trackId': track?.id,
      'title': track?.title ?? 'Not playing',
      'artist': track?.artist ?? 'Open Inzx to start music',
      'isPlaying': state.isPlaying,
      'hasTrack': hasTrack,
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

  static String _fingerprintFrom(Track? track, bool isPlaying, bool hasTrack) {
    final id = track?.id ?? '';
    final title = track?.title ?? '';
    final artist = track?.artist ?? '';
    return '$id|$title|$artist|$isPlaying|$hasTrack';
  }
}
