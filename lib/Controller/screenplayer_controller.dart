import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/Controller/SuggestedVideoController.dart';
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
  var isLiveButtonFocused = false.obs;
  var showSeekFeedback = false.obs;
  var seekFeedbackText = ''.obs;
  var isTopBarFocused = false.obs;

  bool _isRightPressed = false;
  bool _isLeftPressed = false;
  int _lastNavigationTime = 0;
  int _lastBackPressTime = 0;
  Timer? _longPressTimer;
  Timer? _seekDebounceTimer;
  static const _seekDebounceDuration = Duration(milliseconds: 1000);
  static const _backPressThreshold = 2000;

  final SuggestedVideoController suggestedVideoController = Get.find<SuggestedVideoController>();
  late FocusNode liveButtonFocus;
  late FocusNode menuButtonFocus;

  final String _defaultLiveUrl = 'https://mercyott.com/hls_output/master.m3u8';

  @override
  void onInit() {
    super.onInit();
    FocusManager.instance.primaryFocus?.unfocus();
    liveButtonFocus = FocusNode(debugLabel: 'LiveButton');
    menuButtonFocus = FocusNode(debugLabel: 'MenuButton');
    initializePlayer(_defaultLiveUrl, live: true);
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
          suggestedVideoController.update(); // Ensure border sync
          Get.forceAppUpdate(); // Force UI refresh
        }).catchError((error) {
          isVideoInitialized.value = false;
          isBuffering.value = false;
          debugPrint('❌ Error initializing video: $error');
        });

      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.isBuffering != isBuffering.value) {
          isBuffering.value = _videoPlayerController!.value.isBuffering;
          update();
        }
      });
    } catch (e) {
      isVideoInitialized.value = false;
      isBuffering.value = false;
      currentVideoUrl.value = '';
      debugPrint('❌ Error initializing video: $e');
    }
  }

  void disposePlayer() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    isVideoInitialized.value = false;
    isBuffering.value = false;
    isLive.value = false;
    update();
    suggestedVideoController.update(); // Keep border alive
    debugPrint('🗑️ Player disposed');
  }

  void togglePlayPause() {
    if (_videoPlayerController != null) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        debugPrint('⏸️ Video paused');
      } else {
        _videoPlayerController!.play();
        debugPrint('▶️ Video playing');
      }
      resetSuggestedVideoFocus();
      update(); // Notify GetX observers
      suggestedVideoController.update(); // Sync border
      Get.forceAppUpdate(); // Force immediate UI refresh
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

  void seekForwardWithFeedback() {
    if (_videoPlayerController != null && !isLive.value && (_seekDebounceTimer == null || !_seekDebounceTimer!.isActive)) {
      final currentPosition = _videoPlayerController!.value.position;
      final newPosition = currentPosition + const Duration(seconds: 10);
      _videoPlayerController!.seekTo(newPosition).then((_) {
        showSeekFeedback.value = true;
        seekFeedbackText.value = '+10s';
        showControls.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          showSeekFeedback.value = false;
        });
        update();
      });
      _seekDebounceTimer = Timer(_seekDebounceDuration, () {});
      debugPrint('Seek Forward: ${newPosition.inSeconds}s');
    }
  }

  void seekBackwardWithFeedback() {
    if (_videoPlayerController != null && !isLive.value && (_seekDebounceTimer == null || !_seekDebounceTimer!.isActive)) {
      final currentPosition = _videoPlayerController!.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      _videoPlayerController!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition).then((_) {
        showSeekFeedback.value = true;
        seekFeedbackText.value = '-10s';
        showControls.value = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          showSeekFeedback.value = false;
        });
        update();
      });
      _seekDebounceTimer = Timer(_seekDebounceDuration, () {});
      debugPrint('Seek Backward: ${newPosition.inSeconds}s');
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
      disposePlayer();
      initializePlayer(url, live: isLive.value).then((_) {
        if (_videoPlayerController != null) {
          _videoPlayerController!.seekTo(position);
          if (wasPlaying) _videoPlayerController!.play();
        }
      }).catchError((error) {
        debugPrint('❌ Error setting quality: $error');
      });
    }
  }

  void switchToLive() {
    initializePlayer(_defaultLiveUrl, live: true);
    showControls.value = true;
    isTopBarFocused.value = false;
    isLiveButtonFocused.value = false;
    debugPrint('Switched to live video');
  }

  void onScreenTapped() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      liveButtonFocus.unfocus();
      menuButtonFocus.unfocus();
      isLiveButtonFocused.value = false;
      isTopBarFocused.value = false;
      debugPrint('Screen tapped - Controls shown');
    } else {
      debugPrint('Screen tapped - Controls hidden');
    }
    update();
    suggestedVideoController.update(); // Sync border
    Get.forceAppUpdate(); // Force UI refresh
  }

  void resetSuggestedVideoFocus() {
    if (suggestedVideoController.videoData.isNotEmpty) {
      suggestedVideoController.resetFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(Get.context!).requestFocus(
          FocusScope.of(Get.context!).children.elementAt(0),
        );
        suggestedVideoController.update(); // Ensure border sync
        Get.forceAppUpdate();
      });
    }
  }

  void handleKeyEvent(RawKeyEvent event) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (event is RawKeyDownEvent) {
      debugPrint('Key pressed: ${event.logicalKey}');

      switch (event.logicalKey) {
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          showControls.value = !showControls.value;
          if (showControls.value) {
            liveButtonFocus.unfocus();
            menuButtonFocus.unfocus();
            isLiveButtonFocused.value = false;
            isTopBarFocused.value = false;
            debugPrint('OK/Enter pressed - Controls shown');
          } else {
            debugPrint('OK/Enter pressed - Controls hidden');
          }
          _lastNavigationTime = currentTime;
          update();
          suggestedVideoController.update(); // Sync border
          Get.forceAppUpdate();
          break;

        case LogicalKeyboardKey.arrowUp:
          showControls.value = true;
          isTopBarFocused.value = true;
          if (!liveButtonFocus.hasFocus && !menuButtonFocus.hasFocus) {
            FocusScope.of(Get.context!).requestFocus(liveButtonFocus);
            isLiveButtonFocused.value = true;
          } else if (liveButtonFocus.hasFocus) {
            FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
            isLiveButtonFocused.value = false;
          } else if (menuButtonFocus.hasFocus) {
            FocusScope.of(Get.context!).requestFocus(liveButtonFocus);
            isLiveButtonFocused.value = true;
          }
          debugPrint('Up pressed - Live Focused: ${isLiveButtonFocused.value}');
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.arrowDown:
          showControls.value = true;
          isTopBarFocused.value = true;
          if (!liveButtonFocus.hasFocus && !menuButtonFocus.hasFocus) {
            FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
            isLiveButtonFocused.value = false;
          } else if (menuButtonFocus.hasFocus) {
            FocusScope.of(Get.context!).requestFocus(liveButtonFocus);
            isLiveButtonFocused.value = true;
          } else if (liveButtonFocus.hasFocus) {
            FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
            isLiveButtonFocused.value = false;
          }
          debugPrint('Down pressed - Live Focused: ${isLiveButtonFocused.value}');
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.arrowLeft:
          if (!isTopBarFocused.value && !_isLeftPressed) {
            _isLeftPressed = true;
            showControls.value = true;
            if (menuButtonFocus.hasFocus) {
              FocusScope.of(Get.context!).requestFocus(liveButtonFocus);
              isLiveButtonFocused.value = true;
              debugPrint('Left pressed - Focused Live Button from Menu');
            } else if (suggestedVideoController.currentlyPlayingIndex.value > 0) {
              final previousIndex = suggestedVideoController.currentlyPlayingIndex.value;
              suggestedVideoController.moveLeft();
              debugPrint('Left pressed - Moved from $previousIndex to ${suggestedVideoController.currentlyPlayingIndex.value}');
              _adjustScrollPosition(Get.context!, suggestedVideoController.currentlyPlayingIndex.value);
              _lastNavigationTime = currentTime;
              update();
              suggestedVideoController.update();
              Get.forceAppUpdate(); // Instant UI refresh
              _longPressTimer?.cancel();
              _longPressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
                if (_isLeftPressed && suggestedVideoController.currentlyPlayingIndex.value > 0) {
                  final prevIndex = suggestedVideoController.currentlyPlayingIndex.value;
                  suggestedVideoController.moveLeft();
                  debugPrint('Long press Left - Moved from $prevIndex to ${suggestedVideoController.currentlyPlayingIndex.value}');
                  _adjustScrollPosition(Get.context!, suggestedVideoController.currentlyPlayingIndex.value);
                  update();
                  suggestedVideoController.update();
                  Get.forceAppUpdate();
                }
              });
            }
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          if (!isTopBarFocused.value && !_isRightPressed) {
            _isRightPressed = true;
            showControls.value = true;
            if (liveButtonFocus.hasFocus) {
              FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
              isLiveButtonFocused.value = false;
              debugPrint('Right pressed - Focused Menu Button from Live');
            } else if (suggestedVideoController.currentlyPlayingIndex.value < suggestedVideoController.videoData.length - 1) {
              final previousIndex = suggestedVideoController.currentlyPlayingIndex.value;
              suggestedVideoController.moveRight();
              debugPrint('Right pressed - Moved from $previousIndex to ${suggestedVideoController.currentlyPlayingIndex.value}');
              _adjustScrollPosition(Get.context!, suggestedVideoController.currentlyPlayingIndex.value);
              _lastNavigationTime = currentTime;
              update();
              suggestedVideoController.update();
              Get.forceAppUpdate(); // Instant UI refresh
              _longPressTimer?.cancel();
              _longPressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
                if (_isRightPressed && suggestedVideoController.currentlyPlayingIndex.value < suggestedVideoController.videoData.length - 1) {
                  final prevIndex = suggestedVideoController.currentlyPlayingIndex.value;
                  suggestedVideoController.moveRight();
                  debugPrint('Long press Right - Moved from $prevIndex to ${suggestedVideoController.currentlyPlayingIndex.value}');
                  _adjustScrollPosition(Get.context!, suggestedVideoController.currentlyPlayingIndex.value);
                  update();
                  suggestedVideoController.update();
                  Get.forceAppUpdate();
                }
              });
            }
          }
          break;

        case LogicalKeyboardKey.mediaFastForward:
        case LogicalKeyboardKey.mediaTrackNext:
          seekForwardWithFeedback();
          debugPrint('Fast Forward/Next Track pressed');
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.mediaRewind:
        case LogicalKeyboardKey.mediaTrackPrevious:
          seekBackwardWithFeedback();
          debugPrint('Rewind/Previous Track pressed');
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.keyR:
        case LogicalKeyboardKey.f1:
          if (!isLive.value) {
            switchToLive();
          }
          debugPrint('Red/Live pressed');
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.contextMenu:
          showControls.value = true;
          isTopBarFocused.value = true;
          FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
          isLiveButtonFocused.value = false;
          debugPrint('Menu pressed - Focused Menu Button');
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.escape:
          if (showControls.value) {
            showControls.value = false;
            isTopBarFocused.value = false;
            isLiveButtonFocused.value = false;
            debugPrint('Back pressed - Controls hidden');
            _lastBackPressTime = currentTime;
          } else if (isFullScreen.value) {
            toggleFullScreen();
            debugPrint('Back pressed - Exited fullscreen');
            _lastBackPressTime = 0;
          } else {
            switchToLive();
            debugPrint('Back pressed - Returned to live video');
            _lastBackPressTime = currentTime;
          }
          _lastNavigationTime = currentTime;
          break;

        case LogicalKeyboardKey.mediaPlayPause:
        case LogicalKeyboardKey.space:
          togglePlayPause();
          debugPrint('Play/Pause pressed');
          _lastNavigationTime = currentTime;
          break;
      }
    } else if (event is RawKeyUpEvent) {
      debugPrint('Key released: ${event.logicalKey}');
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowRight:
          _isRightPressed = false;
          _longPressTimer?.cancel();
          debugPrint('Right released - Current index: ${suggestedVideoController.currentlyPlayingIndex.value}');
          break;
        case LogicalKeyboardKey.arrowLeft:
          _isLeftPressed = false;
          _longPressTimer?.cancel();
          debugPrint('Left released - Current index: ${suggestedVideoController.currentlyPlayingIndex.value}');
          break;
      }
    }
  }

  void _showExitDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              debugPrint('Exit dialog - Cancelled');
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              debugPrint('Exit dialog - Confirmed, exiting app');
              SystemNavigator.pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _adjustScrollPosition(BuildContext context, int index) {
    const double cardWidth = 180 + 16;
    final ScrollController scrollController = suggestedVideoController.scrollController;

    final targetOffset = index * cardWidth - (MediaQuery.of(context).size.width / 2) + (cardWidth / 2);
    scrollController.animateTo(
      targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    debugPrint('Adjusted scroll to index: $index, Offset: $targetOffset');
  }

  void showPopupMenu(BuildContext context) {
    final RenderBox? button = menuButtonFocus.context?.findRenderObject() as RenderBox?;
    if (button == null) return;
    final Offset offset = button.localToGlobal(Offset.zero);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        offset.dy + button.size.height + 100,
      ),
      items: [
        const PopupMenuItem(value: 'Speed', child: Text('Speed')),
        const PopupMenuItem(value: 'Quality', child: Text('Quality')),
        PopupMenuItem(
          value: 'FullScreen',
          child: Text(isFullScreen.value ? 'Exit Full Screen' : 'Full Screen'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'Speed') {
          showSpeedMenu(context);
        } else if (value == 'Quality') {
          showQualityMenu(context);
        } else if (value == 'FullScreen') {
          toggleFullScreen();
        }
      }
    });
  }

  void showSpeedMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
    ).then((value) {
      if (value != null) {
        setPlaybackSpeed(value);
      }
    });
  }

  void showQualityMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/master.m3u8',
          child: const Text('Auto'),
          onTap: () => setQuality('https://mercyott.com/hls_output/master.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/360p.m3u8',
          child: const Text('360p'),
          onTap: () => setQuality('https://mercyott.com/hls_output/360p.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/720p.m3u8',
          child: const Text('720p'),
          onTap: () => setQuality('https://mercyott.com/hls_output/720p.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/1080p.m3u8',
          child: const Text('1080p'),
          onTap: () => setQuality('https://mercyott.com/hls_output/1080p.m3u8'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setQuality(value);
      }
    });
  }

  @override
  void onClose() {
    disposePlayer();
    _longPressTimer?.cancel();
    _seekDebounceTimer?.cancel();
    liveButtonFocus.dispose();
    menuButtonFocus.dispose();
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