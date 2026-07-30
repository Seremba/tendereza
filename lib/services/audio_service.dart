import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Add a hymn number (as String) here each time you drop an audio file into
/// assets/audio/. Format: '1', '23', 'C1', 'C19' etc.
/// The play button lights up automatically for any number in this set.
const Set<String> kHymnsWithAudio = {};

// ─── State ───────────────────────────────────────────────────────────────────

enum HymnAudioStatus { idle, loading, playing, paused, error }

class HymnAudioState {
  final HymnAudioStatus status;
  final dynamic currentHymn;
  final Duration position;
  final Duration total;

  const HymnAudioState({
    this.status = HymnAudioStatus.idle,
    this.currentHymn,
    this.position = Duration.zero,
    this.total = Duration.zero,
  });

  bool get isPlaying  => status == HymnAudioStatus.playing;
  bool get isLoading  => status == HymnAudioStatus.loading;
  bool get isPaused   => status == HymnAudioStatus.paused;
  bool get isIdle     => status == HymnAudioStatus.idle;

  HymnAudioState copyWith({
    HymnAudioStatus? status,
    dynamic currentHymn,
    bool clearHymn = false,
    Duration? position,
    Duration? total,
  }) =>
      HymnAudioState(
        status:      status      ?? this.status,
        currentHymn: clearHymn ? null : (currentHymn ?? this.currentHymn),
        position:    position    ?? this.position,
        total:       total       ?? this.total,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class HymnAudioNotifier extends StateNotifier<HymnAudioState> {
  HymnAudioNotifier() : super(const HymnAudioState()) {
    _player.onPlayerStateChanged.listen(_onPlayerState);
    _player.onPositionChanged.listen((p) => state = state.copyWith(position: p));
    _player.onDurationChanged.listen((d) => state = state.copyWith(total: d));
    _player.onPlayerComplete.listen((_) => state = const HymnAudioState());
  }

  final AudioPlayer _player = AudioPlayer();

  void _onPlayerState(PlayerState ps) {
    final newStatus = switch (ps) {
      PlayerState.playing   => HymnAudioStatus.playing,
      PlayerState.paused    => HymnAudioStatus.paused,
      PlayerState.stopped   => HymnAudioStatus.idle,
      PlayerState.completed => HymnAudioStatus.idle,
      _                     => state.status,
    };
    state = state.copyWith(status: newStatus);
  }

  /// Returns true if an audio file exists for [hymnNumber].
  static bool hasAudio(dynamic hymnNumber) =>
      kHymnsWithAudio.contains(hymnNumber.toString());

  /// Play/pause toggle for [hymnNumber].
  /// - Same hymn playing  → pause
  /// - Same hymn paused   → resume
  /// - Different hymn     → stop previous, start new
  Future<void> toggle(dynamic hymnNumber) async {
    final numStr = hymnNumber.toString();
    try {
      if (state.currentHymn?.toString() == numStr) {
        if (state.isPlaying) {
          await _player.pause();
        } else {
          await _player.resume();
        }
      } else {
        state = HymnAudioState(
          status: HymnAudioStatus.loading,
          currentHymn: hymnNumber,
        );
        await _player.stop();
        // .mid files play natively on Android via MediaPlayer.
        // iOS does not support MIDI — the play button is hidden on iOS (see hymn_screen.dart).
        await _player.play(AssetSource('audio/$numStr.mid'));
      }
    } catch (_) {
      state = state.copyWith(status: HymnAudioStatus.error);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const HymnAudioState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}


final hymnAudioProvider =
    StateNotifierProvider<HymnAudioNotifier, HymnAudioState>(
        (_) => HymnAudioNotifier());