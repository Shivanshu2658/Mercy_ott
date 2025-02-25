import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class BetterPlayerService {
  BetterPlayerController? _playerController;

  BetterPlayerController? get playerController => _playerController;

  Future<void> initializePlayer(String videoUrl) async {
    try {
      disposePlayer();

      debugPrint('🎬 Setting up BetterPlayer with URL: $videoUrl');

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        liveStream: videoUrl.contains(".m3u8"),
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 5000,
          maxBufferMs: 10000,
          bufferForPlaybackMs: 2500,
          bufferForPlaybackAfterRebufferMs: 5000,
        ),
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          maxCacheSize: 10 * 1024 * 1024,
          maxCacheFileSize: 10 * 1024 * 1024,
        ),
      );

      _playerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          fit: BoxFit.contain,
          aspectRatio: 16 / 9,
          handleLifecycle: true,
          autoDetectFullscreenAspectRatio: true,
          errorBuilder: (context, errorMessage) => Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enablePlayPause: true,
            enableFullscreen: true,
            enableSkips: false,
          ),
        ),
      );

      await _playerController!.setupDataSource(dataSource);
       _playerController!.setMixWithOthers(true);
      
      debugPrint('✅ BetterPlayer setup complete');
    } catch (e) {
      debugPrint('❌ Error initializing BetterPlayer: $e');
      rethrow;
    }
  }

  void disposePlayer() {
    _playerController?.pause();
    _playerController?.dispose();
    _playerController = null;
    debugPrint('🗑️ BetterPlayer disposed');
  }
}