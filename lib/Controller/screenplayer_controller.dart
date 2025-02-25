import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/widget/screen_player.dart';
import 'package:video_player/video_player.dart';

class ScreenPlayerController extends GetxController {
  VideoPlayerController? _videoPlayerController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  var isVideoInitialized = false.obs;
  var isBuffering = false.obs;
  var showControls = false.obs;
  var currentVideoUrl = ''.obs;
  var isFullScreen = false.obs;
  var isLive = false.obs;
  Timer? _hideControlsTimer;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> initializePlayer(String videoUrl, {bool live = false}) async {
    if (currentVideoUrl.value == videoUrl && isVideoInitialized.value) {
      debugPrint('🎥 Video already initialized: $videoUrl');
      _videoPlayerController?.play();
      return;
    }

    try {
      isVideoInitialized.value = false;
      isBuffering.value = true;
      disposePlayer();

      debugPrint('🎥 Initializing video: $videoUrl (Live: $live)');
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          currentVideoUrl.value = videoUrl;
          isLive.value = live;
          isVideoInitialized.value = true;
          isBuffering.value = false;
          _videoPlayerController!.play();
          debugPrint('✅ Video playback started');
          update();
        }).catchError((error) {
          isVideoInitialized.value = false;
          isBuffering.value = false;
          debugPrint('❌ Error initializing video: $error');
          showErrorDialog('Failed to load video: $error');
        });

      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.isBuffering != isBuffering.value) {
          isBuffering.value = _videoPlayerController!.value.isBuffering;
          update();
        }
        update(); // Continuously update for progress bar
      });
    } catch (e) {
      isVideoInitialized.value = false;
      isBuffering.value = false;
      currentVideoUrl.value = '';
      debugPrint('❌ Error initializing video: $e');
      showErrorDialog('Failed to load video: $e');
    }
  }

  void disposePlayer() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    isVideoInitialized.value = false;
    isBuffering.value = false;
    isLive.value = false;
    currentVideoUrl.value = '';
    update();
    debugPrint('🗑️ Player disposed');
  }

  void togglePlayPause() {
    if (_videoPlayerController != null) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      update();
    }
  }

  void toggleFullScreen() {
    isFullScreen.value = !isFullScreen.value;
    if (isFullScreen.value) {
      Get.to(() => ScreenPlayer(videoUrl: currentVideoUrl.value));
    } else {
      Get.back();
    }
  }

  void seekForward() {
    if (_videoPlayerController != null && !isLive.value) {
      final currentPosition = _videoPlayerController!.value.position;
      final newPosition = currentPosition + const Duration(seconds: 10);
      _videoPlayerController!.seekTo(newPosition);
    }
  }

  void seekBackward() {
    if (_videoPlayerController != null && !isLive.value) {
      final currentPosition = _videoPlayerController!.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      _videoPlayerController!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    }
  }

  void setPlaybackSpeed(double speed) {
    if (_videoPlayerController != null) {
      _videoPlayerController!.setPlaybackSpeed(speed);
      update();
    }
  }

  void setQuality(String url) {
    if (_videoPlayerController != null) {
      final wasPlaying = _videoPlayerController!.value.isPlaying;
      final position = _videoPlayerController!.value.position;
      initializePlayer(url, live: isLive.value).then((_) {
        _videoPlayerController!.seekTo(position);
        if (wasPlaying) _videoPlayerController!.play();
      });
    }
  }

  void switchToLive() {
    initializePlayer('https://mercyott.com/hls_output/720p.m3u8', live: true);
  }

  void onScreenTapped() {
    showControls.value = !showControls.value;
    _hideControlsTimer?.cancel();
    if (showControls.value) {
      _hideControlsTimer = Timer(const Duration(seconds: 4), () {
        showControls.value = false;
        update();
      });
    }
    update();
  }

  void showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Video Error'),
        content: Text('$message\n\nPlease provide a valid video URL.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              initializePlayer('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4');
            },
            child: const Text('Retry with Test URL'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    disposePlayer();
    _hideControlsTimer?.cancel();
    super.onClose();
    debugPrint('🛑 ScreenPlayerController closed');
  }

  String getPosition() {
    if (_videoPlayerController == null) return '0:00';
    final position = _videoPlayerController!.value.position;
    return '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  String getDuration() {
    if (_videoPlayerController == null) return '0:00';
    final duration = _videoPlayerController!.value.duration;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  double getProgress() {
    if (_videoPlayerController == null || _videoPlayerController!.value.duration.inSeconds == 0) return 0.0;
    return _videoPlayerController!.value.position.inSeconds / _videoPlayerController!.value.duration.inSeconds;
  }
}