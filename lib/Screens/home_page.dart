import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/Controller/SuggestedVideoController.dart';
import 'package:mercy_tv_app/Controller/home_controller.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';
import 'package:mercy_tv_app/widget/sugested_video_list.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    final playerController = Get.find<ScreenPlayerController>();

    if (!playerController.isLive.value) {
      playerController.switchToLive();
      return false;
    }

    final bool? result = await Get.dialog(
      AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Do you really want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Yes"),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final ScreenPlayerController playerController =
        Get.find<ScreenPlayerController>();
    final FocusNode focusNode = FocusNode()..requestFocus();

    void onVideoTap(ProgramDetails programDetails) {
      homeController.playVideo(programDetails);
      playerController.showControls.value = false;
    }

    playerController.setOnVideoTap(onVideoTap);

    return WillPopScope(
        onWillPop: () => _onWillPop(context),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Color.fromARGB(255, 0, 90, 87),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.9],
              ),
            ),
            child: RawKeyboardListener(
              focusNode: focusNode,
              onKey: playerController.handleKeyEvent,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: Obx(() {
                      if (!playerController.isVideoInitialized.value) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Loading video...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }
                      return FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: playerController
                              .videoPlayerController!.value.size.width,
                          height: playerController
                              .videoPlayerController!.value.size.height,
                          child: VideoPlayer(
                              playerController.videoPlayerController!),
                        ),
                      );
                    }),
                  ),
                  GestureDetector(
                    onTap: playerController.onScreenTapped,
                    behavior: HitTestBehavior.opaque,
                    child: Obx(() => AnimatedOpacity(
                          opacity:
                              playerController.showControls.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            color: Colors.black54,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Focus(
                                        focusNode:
                                            playerController.liveButtonFocus,
                                        onKeyEvent: (node, event) {
                                          final controller = Get.find<
                                              SuggestedVideoController>();
                                          if (event is KeyDownEvent) {
                                            if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowUp) {
                                              // Close the suggested video list
                                              Get.find<SuggestedVideoController>().hideSuggestedVideoList(true);

                                              return KeyEventResult.handled;
                                            } else if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowLeft) {
                                              controller.moveLeft();
                                              return KeyEventResult.handled;
                                            } else if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowRight) {
                                              controller.moveRight();
                                              return KeyEventResult.handled;
                                            } else if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowDown) {
                                              Get.find<SuggestedVideoController>().hideSuggestedVideoList(false);

                                              return KeyEventResult.handled;
                                            }
                                          } else if (event is KeyUpEvent) {
                                            // controller.scrollToIndex(controller.currentlyPlayingIndex.value);
                                            Get.find<SuggestedVideoController>()
                                                .restoreFocus();
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: Obx(() => AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              decoration: BoxDecoration(
                                                border: playerController
                                                        .isLiveButtonFocused
                                                        .value
                                                    ? Border.all(
                                                        color: Colors.white,
                                                        width: 2)
                                                    : null,
                                              ),
                                              child: Container(
                                                height: 20,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  color: playerController
                                                          .isLive.value
                                                      ? Colors.red
                                                      : const Color(0xFF8DBDCC),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: TextButton(
                                                  onPressed: playerController
                                                          .isLive.value
                                                      ? null
                                                      : () => playerController
                                                          .switchToLive(),
                                                  style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero),
                                                  child: Text(
                                                    playerController
                                                            .isLive.value
                                                        ? 'Live'
                                                        : 'Go Live',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                            )),
                                      ),
                                      Focus(
                                        focusNode:
                                            playerController.menuButtonFocus,
                                        child: Obx(() => AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              decoration: BoxDecoration(
                                                border: !playerController
                                                            .isLiveButtonFocused
                                                            .value &&
                                                        playerController
                                                            .menuButtonFocus
                                                            .hasFocus
                                                    ? Border.all(
                                                        color: Colors.white,
                                                        width: 2)
                                                    : null,
                                              ),
                                              child: PopupMenuButton<String>(
                                                icon: const Icon(
                                                    Icons.more_vert,
                                                    color: Colors.white),
                                                onSelected: (value) {
                                                  if (value == 'Speed') {
                                                    playerController
                                                        .showSpeedMenu(context);
                                                  } else if (value ==
                                                      'Quality') {
                                                    playerController
                                                        .showQualityMenu(
                                                            context);
                                                  }
                                                },
                                                itemBuilder: (context) {
                                                  List<PopupMenuEntry<String>>
                                                      items = [
                                                    const PopupMenuItem(
                                                        value: 'Speed',
                                                        child: Text('Speed')),
                                                  ];
                                                  if (playerController
                                                      .isLive.value) {
                                                    items.add(
                                                        const PopupMenuItem(
                                                            value: 'Quality',
                                                            child: Text(
                                                                'Quality')));
                                                  }
                                                  return items;
                                                },
                                                // itemBuilder: (context) => [
                                                //   const PopupMenuItem(value: 'Speed', child: Text('Speed')),
                                                //   const PopupMenuItem(value: 'Quality', child: Text('Quality')),
                                                // ],
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                                ////
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Obx(() {
                                    return Get.find<SuggestedVideoController>()
                                            .showSuggestedList
                                            .value
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 180,
                                                color: Colors.black54,
                                                child: SuggestedVideoCard(
                                                    onVideoTap: onVideoTap),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.replay_10,
                                                        color: Colors.white,
                                                        size: 40),
                                                    onPressed: playerController
                                                        .seekBackwardWithFeedback,
                                                  ),
                                                  const SizedBox(width: 20),
                                                  IconButton(
                                                    icon: Icon(
                                                      playerController
                                                              .videoPlayerController!
                                                              .value
                                                              .isPlaying
                                                          ? Icons.pause
                                                          : Icons.play_arrow,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                                    onPressed: playerController
                                                        .togglePlayPause,
                                                  ),
                                                  const SizedBox(width: 20),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.forward_10,
                                                        color: Colors.white,
                                                        size: 40),
                                                    onPressed: playerController
                                                        .seekForwardWithFeedback,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (!playerController
                                                  .isLive.value)
                                                Slider(
                                                  value: playerController
                                                      .videoPlayerController!
                                                      .value
                                                      .position
                                                      .inSeconds
                                                      .toDouble(),
                                                  min: 0.0,
                                                  max: playerController
                                                      .videoPlayerController!
                                                      .value
                                                      .duration
                                                      .inSeconds
                                                      .toDouble(),
                                                  activeColor: Colors.red,
                                                  inactiveColor: Colors.grey,
                                                  onChanged: (double newValue) {
                                                    playerController
                                                        .videoPlayerController!
                                                        .seekTo(Duration(
                                                            seconds: newValue
                                                                .toInt()));
                                                  },
                                                ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  playerController.isLive.value
                                                      ? const Text(
                                                          'LIVE',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : Text(
                                                          '${playerController.getPosition()} / ${playerController.getDuration()}',
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16),
                                                        ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.fullscreen,
                                                        color: Colors.white,
                                                        size: 30),
                                                    onPressed: playerController
                                                        .toggleFullScreen,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink();
                                  }),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
