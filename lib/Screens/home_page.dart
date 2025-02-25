import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/Controller/home_controller.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';
import 'package:mercy_tv_app/widget/button_section.dart';
import 'package:mercy_tv_app/widget/sugested_video_list.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();
  final ScreenPlayerController playerController =
      Get.find<ScreenPlayerController>();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            // Video Player Section (Strictly 70% of screen height)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return playerController.isVideoInitialized.value &&
                          !playerController.isBuffering.value &&
                          playerController.videoPlayerController != null
                      ? Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                clipBehavior:
                                    Clip.hardEdge, // Ensure no overflow
                                child: SizedBox(
                                  width: playerController
                                      .videoPlayerController!.value.size.width,
                                  height: playerController
                                      .videoPlayerController!.value.size.height,
                                  child: VideoPlayer(
                                      playerController.videoPlayerController!),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: playerController.onScreenTapped,
                                behavior: HitTestBehavior.opaque,
                              ),
                            ),
                            Obx(() => playerController.showControls.value
                                ? Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
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
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                    Icons.more_vert,
                                                    color: Colors.white),
                                                onSelected: (value) {
                                                  if (value == 'Speed') {
                                                    _showSpeedMenu(context);
                                                  } else if (value ==
                                                      'Quality') {
                                                    _showQualityMenu(context);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'Speed',
                                                    child: Text('Speed'),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'Quality',
                                                    child: Text('Quality'),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                                                    .seekBackward,
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
                                                    .seekForward,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              if (!playerController.isLive
                                                  .value) 
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
                                                  onChanged: (value) {
                                                    playerController
                                                        .videoPlayerController!
                                                        .seekTo(Duration(
                                                            seconds:
                                                                value.toInt()));
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox()),
                          ],
                        )
                      : const Center(
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
                }),
              ),
            ),

            // Content Section (Below Video Player, Remaining 30%)
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          homeController.selectedProgramTitle.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          children: [
                            Text(
                              homeController
                                      .selectedProgramDate.value.isNotEmpty
                                  ? homeController.selectedProgramDate.value
                                  : DateFormat('EEE dd MMM').format(
                                      homeController.currentDateTime.value),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            const Text("|",
                                style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 8),
                            Text(
                              homeController
                                      .selectedProgramTime.value.isNotEmpty
                                  ? homeController.selectedProgramTime.value
                                  : DateFormat('hh:mm a').format(
                                      homeController.currentDateTime.value),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                          ],
                        )),
                    const SizedBox(height: 10),
                    const ButtonSection(),
                    const SizedBox(height: 15),
                    const Text(
                      'Past Programs',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 10),
                    Container(
                        width: 138, height: 2, color: CustomColors.buttonColor),
                    const SizedBox(height: 20),
                    SuggestedVideoCard(
                      onVideoTap: (ProgramDetails programDetails) {
                        homeController.playVideo(programDetails);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedMenu(BuildContext context) {
    final controller = Get.find<ScreenPlayerController>();
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
        controller.setPlaybackSpeed(value);
      }
    });
  }

  void _showQualityMenu(BuildContext context) {
    final controller = Get.find<ScreenPlayerController>();
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/master.m3u8',
          child: const Text('Auto'),
          onTap: () => controller
              .setQuality('https://mercyott.com/hls_output/master.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/360p.m3u8',
          child: const Text('360p'),
          onTap: () => controller
              .setQuality('https://mercyott.com/hls_output/360p.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/720p.m3u8',
          child: const Text('720p'),
          onTap: () => controller
              .setQuality('https://mercyott.com/hls_output/720p.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/1080p.m3u8',
          child: const Text('1080p'),
          onTap: () => controller
              .setQuality('https://mercyott.com/hls_output/1080p.m3u8'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        controller.setQuality(value);
      }
    });
  }
}
