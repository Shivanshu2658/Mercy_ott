import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/Controller/SuggestedVideoController.dart';
import 'package:mercy_tv_app/widget/screen_player.dart';
import 'package:video_player/video_player.dart';

class ScreenPlayerController extends GetxController {
  VideoPlayerController? _videoPlayerController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  var isVideoInitialized = false.obs;
  var isBuffering = false.obs;
  var showControls = true.obs;
  var currentVideoUrl = ''.obs;
  var isFullScreen = false.obs;
  var isLive = false.obs;
  var isLiveButtonFocused = false.obs;
  var showSeekFeedback = false.obs;
  var seekFeedbackText = ''.obs;
  var isTopBarFocused = false.obs;

  bool _isRightPressed = false;
  bool _isLeftPressed = false;
  Timer? _seekDebounceTimer;
  Timer? _longPressStartTimer;
  Timer? _longPressTimer;

  late void Function(ProgramDetails) _onVideoTap;

  static const _seekDebounceDuration = Duration(milliseconds: 10);

  final SuggestedVideoController suggestedVideoController =
      Get.find<SuggestedVideoController>();
  late FocusNode liveButtonFocus;
  late FocusNode menuButtonFocus;

  final String _defaultLiveUrl = 'https://mercyott.com/hls_output/master.m3u8';

  @override
  void onInit() {
    super.onInit();
    FocusManager.instance.primaryFocus?.unfocus();
    liveButtonFocus = FocusNode(debugLabel: 'LiveButton');
    menuButtonFocus = FocusNode(debugLabel: 'MenuButton');
    _onVideoTap = (ProgramDetails details) {
      debugPrint('Default _onVideoTap called - not set yet');
    };
    initializePlayer(_defaultLiveUrl, live: true);
  }

  void setOnVideoTap(void Function(ProgramDetails) onVideoTap) {
    _onVideoTap = onVideoTap;
    debugPrint('onVideoTap callback set successfully');
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
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl))
            ..initialize().then((_) {
              currentVideoUrl.value = videoUrl;
              isLive.value = live;
              isVideoInitialized.value = true;
              isBuffering.value = false;
              _videoPlayerController!.play();
              debugPrint('✅ Video playback started');
              update();
              suggestedVideoController.update();
              Get.forceAppUpdate();
              _focusFirstCard();
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
    suggestedVideoController.update();
    debugPrint('🗑️ Player disposed');
  }

  void togglePlayPause() {
    if (_videoPlayerController != null) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        Get.find<ScreenPlayerController>().showControls.value = true;

        debugPrint('⏸️ Video paused');
      } else {
        _videoPlayerController!.play();
        Get.find<ScreenPlayerController>().showControls.value = false;
        debugPrint('▶️ Video playing');
      }
      resetSuggestedVideoFocus();
      update();
      suggestedVideoController.update();
      Get.forceAppUpdate();
    }
  }

  // void toggleFullScreen() {
  //   isFullScreen.value = !isFullScreen.value;
  //   if (isFullScreen.value) {
  //     Get.to(() => ScreenPlayer(videoUrl: currentVideoUrl.value));
  //   } else {
  //     Get.back();
  //   }
  //   update();
  // }

  void seekForwardWithFeedback() {
    if (_videoPlayerController != null &&
        !isLive.value &&
        (_seekDebounceTimer == null || !_seekDebounceTimer!.isActive)) {
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
    if (_videoPlayerController != null &&
        !isLive.value &&
        (_seekDebounceTimer == null || !_seekDebounceTimer!.isActive)) {
      final currentPosition = _videoPlayerController!.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      _videoPlayerController!
          .seekTo(newPosition < Duration.zero ? Duration.zero : newPosition)
          .then((_) {
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
    print("{}{}{}{}{}{}{}{}{}{}");
    initializePlayer(_defaultLiveUrl, live: true);
    showControls.value = true;
    isTopBarFocused.value = false;
    isLiveButtonFocused.value = false;
    debugPrint('Switched to live video');
    _focusFirstCard();
  }

  void onScreenTapped() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      isLiveButtonFocused.value = false;
      isTopBarFocused.value = false;
      debugPrint('Screen tapped - Controls shown, focusing first card');
    } else {
      liveButtonFocus.unfocus();
      menuButtonFocus.unfocus();
      isLiveButtonFocused.value = false;
      isTopBarFocused.value = false;

      debugPrint('Screen tapped - Controls hidden');
    }
    _focusFirstCard();
    update();
    suggestedVideoController.update();
    Get.forceAppUpdate();
  }

  void resetSuggestedVideoFocus() {
    if (suggestedVideoController.videoData.isNotEmpty) {
      suggestedVideoController.resetFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null &&
            suggestedVideoController.videoFocusNodes.isNotEmpty) {
          FocusScope.of(Get.context!).requestFocus(
            suggestedVideoController.videoFocusNodes[
                suggestedVideoController.currentlyPlayingIndex.value],
          );
          debugPrint(
              'Reset focus to index: ${suggestedVideoController.currentlyPlayingIndex.value}');
          suggestedVideoController.update();
          Get.forceAppUpdate();
        }
      });
    }
  }

  void _focusFirstCard() {
    if (suggestedVideoController.videoData.isEmpty) {
      debugPrint('No suggested videos to focus');
      return;
    }

    suggestedVideoController.currentlyPlayingIndex.value = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null &&
          suggestedVideoController.videoFocusNodes.isNotEmpty &&
          suggestedVideoController.scrollController.hasClients) {
        FocusScope.of(Get.context!)
            .requestFocus(suggestedVideoController.videoFocusNodes[0]);
        // _adjustScrollPosition(Get.context!);
        resetFocusToFirstItem();
        debugPrint('Focused first card at index: 0');
        update();
        suggestedVideoController.update();
        Get.forceAppUpdate();
      }
    });
  }

  // void _startLongPressLeft() {
  //   _longPressTimer?.cancel();
  //   _longPressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
  //     if (!_isLeftPressed) {
  //       timer.cancel();
  //       debugPrint('Long press Left stopped due to release');
  //       return;
  //     }
  //     if (suggestedVideoController.currentlyPlayingIndex.value > 0) {
  //       final prevIndex = suggestedVideoController.currentlyPlayingIndex.value;
  //       suggestedVideoController.moveLeft();
  //       _updateFocusAndScroll(prevIndex, suggestedVideoController.currentlyPlayingIndex.value, 'Long press Left');
  //     } else {
  //       timer.cancel();
  //       debugPrint('Long press Left stopped at start');
  //     }
  //   });
  // }
  //
  // void _startLongPressRight() {
  //   _longPressTimer?.cancel();
  //   _longPressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
  //     if (!_isRightPressed) {
  //       timer.cancel();
  //       debugPrint('Long press Right stopped due to release');
  //       return;
  //     }
  //     if (suggestedVideoController.currentlyPlayingIndex.value < suggestedVideoController.videoData.length - 1) {
  //       final prevIndex = suggestedVideoController.currentlyPlayingIndex.value;
  //       suggestedVideoController.moveRight();
  //       _updateFocusAndScroll(prevIndex, suggestedVideoController.currentlyPlayingIndex.value, 'Long press Right');
  //     } else {
  //       timer.cancel();
  //       debugPrint('Long press Right stopped at end');
  //     }
  //   });
  // }
  void _startLongPressLeft() {
    _longPressTimer?.cancel();
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isLeftPressed || !suggestedVideoController.canMoveLeft) {
        timer.cancel();
        return;
      }
      suggestedVideoController.moveLeft();
    });
  }

  void _startLongPressRight() {
    _longPressTimer?.cancel();
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isRightPressed || !suggestedVideoController.canMoveRight) {
        timer.cancel();
        return;
      }
      suggestedVideoController.moveRight();
    });
  }

  void _updateFocusAndScroll(int prevIndex, int newIndex, String direction) {
    if (Get.context != null &&
        suggestedVideoController.videoFocusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(Get.context!)
            .requestFocus(suggestedVideoController.videoFocusNodes[newIndex]);
        debugPrint('$direction - Forced focus on index: $newIndex');
      });
      debugPrint('$direction - Moved from $prevIndex to $newIndex');
      _adjustScrollPosition(Get.context!);
    }
  }

// Add these at the top of your class
  DateTime _lastArrowKeyPressTime = DateTime.now();
  final Duration _arrowKeyCooldown =
      Duration(milliseconds: 300); // Adjust if needed

  KeyEventResult handleKeyEvent(RawKeyEvent event) {
    debugPrint('Key event: ${event.logicalKey}, Type: ${event.runtimeType}');

    // if (event is RawKeyDownEvent) {
    if (event is RawKeyDownEvent && !event.repeat) {
      // Throttle all arrow key events
      final now = DateTime.now();
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (now.difference(_lastArrowKeyPressTime) < _arrowKeyCooldown) {
          debugPrint('Arrow key ignored due to cooldown');
          return KeyEventResult.handled;
        }
        _lastArrowKeyPressTime = now;
      }

      if (event.repeat) {
        debugPrint('Ignoring repeat event');
        return KeyEventResult.handled;
      }

      switch (event.logicalKey) {
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          debugPrint('Enter/Select pressed');
          if (liveButtonFocus.hasFocus && !isLive.value) {
            switchToLive();
            debugPrint('Enter pressed - Switched to live');
          } else if (menuButtonFocus.hasFocus) {
            showPopupMenu(Get.context!);

            ///
            debugPrint('Enter pressed - Menu opened');
          } else if (suggestedVideoController.videoFocusNodes.isNotEmpty &&
              showControls.value) {
            final currentIndex =
                suggestedVideoController.currentlyPlayingIndex.value;
            debugPrint(
                'Video card selected at index $currentIndex (controls visible)');
            // Construct ProgramDetails and call onVideoTap directly
            final video = suggestedVideoController.videoData[currentIndex];
            final program = video['program'] ?? {};
            final programDetails = ProgramDetails(
              imageUrl: program['image'],
              date: program['date'],
              time: program['time'],
              title: program['program'] ?? 'Unknown Program',
              videoUrl: video['url'] ?? '',
            );
            debugPrint(
                'Playing video at index $currentIndex: ${programDetails.videoUrl}');
            _onVideoTap(programDetails);
            // Hide controls explicitly
            showControls.value = false;

            update();
            Get.forceAppUpdate();
          } else {
            debugPrint(
                'No video focus or controls not visible - toggling controls');
            showControls.value = !showControls.value;
            if (showControls.value) {
              debugPrint('Controls shown, focusing first card');
              // _focusFirstCard();
            } else {
              liveButtonFocus.unfocus();
              menuButtonFocus.unfocus();
              isLiveButtonFocused.value = false;
              isTopBarFocused.value = false;
              debugPrint('Controls hidden');
            }
            _focusFirstCard();
          }
          update();
          suggestedVideoController.update();
          Get.forceAppUpdate();
          break;

        case LogicalKeyboardKey.arrowUp:
          suggestedVideoController.hideSuggestedVideoList(false);

          /// if else shivanshu added
          if (!isLiveButtonFocused.value) {
            showControls.value = true;
            isTopBarFocused.value = true;
            FocusScope.of(Get.context!).requestFocus(liveButtonFocus);
            isLiveButtonFocused.value = true;
            debugPrint('Up pressed - Live button focused11111');
            update();
            break;
          } else {
            showControls.value = true;
            isLiveButtonFocused.value = true;
            isTopBarFocused.value = true;
          }
          break;

        case LogicalKeyboardKey.arrowDown:

          // suggestedVideoController.hideSuggestedVideoList(true);
          showControls.value = true;
          // resetFocusToFirstItem();

          if (liveButtonFocus.hasFocus) {
            // FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
            isLiveButtonFocused.value = false;
            isTopBarFocused.value = true;
          } else if (menuButtonFocus.hasFocus &&
              suggestedVideoController.videoData.isNotEmpty) {
            isLiveButtonFocused.value = false;
            isTopBarFocused.value = true;


            // FocusScope.of(Get.context!).requestFocus(
            //     suggestedVideoController.videoFocusNodes[
            //         suggestedVideoController.currentlyPlayingIndex.value]);
          }
          suggestedVideoController.hideSuggestedVideoList(true);
          FocusScope.of(Get.context!).requestFocus(
              suggestedVideoController.videoFocusNodes[
              0]);
          update();
          Get.forceAppUpdate();
          break;

        case LogicalKeyboardKey.arrowLeft:
          final now = DateTime.now();
          if (now.difference(_lastArrowKeyPressTime) < _arrowKeyCooldown) {
            debugPrint('Arrow LEFT ignored due to cooldown');
            return KeyEventResult.handled;
          }
          _lastArrowKeyPressTime = now;

          if (!isTopBarFocused.value &&
              suggestedVideoController.videoData.isNotEmpty &&
              suggestedVideoController.scrollController.hasClients) {
            _handleLeftMovement();
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          final now = DateTime.now();
          if (now.difference(_lastArrowKeyPressTime) < _arrowKeyCooldown) {
            debugPrint('Arrow RIGHT ignored due to cooldown');
            return KeyEventResult.handled;
          }
          _lastArrowKeyPressTime = now;

          if (!isTopBarFocused.value &&
              suggestedVideoController.videoData.isNotEmpty &&
              suggestedVideoController.scrollController.hasClients) {
            _handleRightMovement();
          }
          break;

        case LogicalKeyboardKey.mediaFastForward:
        case LogicalKeyboardKey.mediaTrackNext:
          seekForwardWithFeedback();
          debugPrint('Fast Forward/Next Track pressed');
          break;

        case LogicalKeyboardKey.mediaRewind:
        case LogicalKeyboardKey.mediaTrackPrevious:
          seekBackwardWithFeedback();
          debugPrint('Rewind/Previous Track pressed');
          break;

        case LogicalKeyboardKey.keyR:
        case LogicalKeyboardKey.f1:
          if (!isLive.value) {
            switchToLive();
          }
          debugPrint('Red/Live pressed');
          break;

        case LogicalKeyboardKey.contextMenu:
          showControls.value = true;
          isTopBarFocused.value = true;
          FocusScope.of(Get.context!).requestFocus(menuButtonFocus);
          isLiveButtonFocused.value = false;
          debugPrint('Menu pressed - Focused Menu Button');
          break;

        /// will work on this
        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.escape:
          final suggestedController = Get.find<SuggestedVideoController>();

          // Close suggested list if visible
          if (suggestedController.showSuggestedList.value) {
            suggestedController.hideSuggestedVideoList(false); // Hide the list
            update();
            return KeyEventResult.handled; // Exit after closing the list
          }

          if (!isLive.value) {
            switchToLive();
            update();
            return KeyEventResult.handled;
          }
          if (isLive.value && showControls.value) {
            showControls.value = false;
            isTopBarFocused.value = false;
            isLiveButtonFocused.value = false;
            debugPrint('Back pressed - Controls hidden');
          } else if (isLive.value && isFullScreen.value) {
            // toggleFullScreen();
            debugPrint('Back pressed - Exited fullscreen');
          } else if (isLive.value) {
            _showExitDialog();
            debugPrint('Back pressed - Showing exit dialog');
          }
          update();
          break;

        case LogicalKeyboardKey.mediaPlayPause:
        case LogicalKeyboardKey.space:
          togglePlayPause();
          debugPrint('Play/Pause pressed');
          break;
      }
    }

    return KeyEventResult.ignored;

    // else if (event is RawKeyUpEvent) {
    //   debugPrint('Key released: ${event.logicalKey}');
    //   switch (event.logicalKey) {
    //     case LogicalKeyboardKey.arrowRight:
    //       _isRightPressed = false;
    //       _longPressStartTimer?.cancel();
    //       _longPressTimer?.cancel();
    //       if (suggestedVideoController.videoData.isNotEmpty &&
    //           Get.context != null) {
    //         FocusScope.of(Get.context!).requestFocus(
    //             suggestedVideoController.videoFocusNodes[
    //                 suggestedVideoController.currentlyPlayingIndex.value]);
    //         _adjustScrollPosition(Get.context!);
    //         debugPrint(
    //             'Right released - Stopped at index: ${suggestedVideoController.currentlyPlayingIndex.value}');
    //         update();
    //         suggestedVideoController.update();
    //         Get.forceAppUpdate();
    //       }
    //       break;
    //     case LogicalKeyboardKey.arrowLeft:
    //       _isLeftPressed = false;
    //       _longPressStartTimer?.cancel();
    //       _longPressTimer?.cancel();
    //       if (suggestedVideoController.videoData.isNotEmpty &&
    //           Get.context != null) {
    //         FocusScope.of(Get.context!).requestFocus(
    //             suggestedVideoController.videoFocusNodes[
    //                 suggestedVideoController.currentlyPlayingIndex.value]);
    //         _adjustScrollPosition(Get.context!);
    //         debugPrint(
    //             'Left released - Stopped at index: ${suggestedVideoController.currentlyPlayingIndex.value}');
    //         update();
    //         suggestedVideoController.update();
    //         Get.forceAppUpdate();
    //       }
    //       break;
    //   }
    // }
  }

  void _showExitDialog() {
    if (Get.context == null) {
      debugPrint('❌ No context available for exit dialog');
      return;
    }
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

  void _adjustScrollPosition(BuildContext context) {
    if (!suggestedVideoController.scrollController.hasClients) {
      debugPrint("ScrollController not attached, skipping adjustment");
      return;
    }
    const double cardWidth = 180 + 16;
    final ScrollController scrollController =
        suggestedVideoController.scrollController;
    int index = suggestedVideoController.currentlyPlayingIndex.value;

    final targetOffset = index * cardWidth -
        (MediaQuery.of(context).size.width / 2) +
        (cardWidth / 2);
    scrollController
        .animateTo(
      targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      if (suggestedVideoController.videoFocusNodes.isNotEmpty) {
        FocusScope.of(context)
            .requestFocus(suggestedVideoController.videoFocusNodes[index]);
        update();
        suggestedVideoController.update();
        Get.forceAppUpdate();
        debugPrint('Scroll completed - Refocused index: $index');
      }
    });
    debugPrint('Adjusted scroll to index: $index, Offset: $targetOffset');
  }

  void showPopupMenu(BuildContext context) {
    final RenderBox? button =
        menuButtonFocus.context?.findRenderObject() as RenderBox?;
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
          // toggleFullScreen();
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
          onTap: () =>
              setQuality('https://mercyott.com/hls_output/master.m3u8'),
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
    );
  }

  /// shivanshu added
  void resetFocusToFirstItem() {
    suggestedVideoController.currentlyPlayingIndex.value = 0;

    if (Get.context != null &&
        suggestedVideoController.videoFocusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(Get.context!).requestFocus(
          suggestedVideoController.videoFocusNodes[0],
        );
        debugPrint('Reset focus to index 0');
      });
    }
  }

  void _handleLeftMovement() {
    _isLeftPressed = true;
    showControls.value = true;
    _longPressStartTimer?.cancel();

    // Immediate single press action
    if (suggestedVideoController.canMoveLeft) {
      final prevIndex = suggestedVideoController.currentlyPlayingIndex.value;
      suggestedVideoController.moveLeft();
      _updateFocusAndScroll(
          prevIndex,
          suggestedVideoController.currentlyPlayingIndex.value,
          'Single tap Left');
    }

    // Configure long press behavior
    _longPressStartTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isLeftPressed) {
        _startLongPressLeft();
      }
    });
  }

  void _handleRightMovement() {
    _isRightPressed = true;
    showControls.value = true;
    _longPressStartTimer?.cancel();

    // Immediate single press action
    if (suggestedVideoController.canMoveRight) {
      final prevIndex = suggestedVideoController.currentlyPlayingIndex.value;
      suggestedVideoController.moveRight();
      _updateFocusAndScroll(
          prevIndex,
          suggestedVideoController.currentlyPlayingIndex.value,
          'Single tap Right');
    }

    // Configure long press behavior
    _longPressStartTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isRightPressed) {
        _startLongPressRight();
      }
    });
  }

  /// shivanshu added

  @override
  void onClose() {
    disposePlayer();
    _seekDebounceTimer?.cancel();
    _longPressStartTimer?.cancel();
    _longPressTimer?.cancel();
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
    if (_videoPlayerController == null ||
        _videoPlayerController!.value.duration.inSeconds == 0) return 0.0;
    return _videoPlayerController!.value.position.inSeconds /
        _videoPlayerController!.value.duration.inSeconds;
  }
}
