import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';
import 'package:video_player/video_player.dart';

class ScreenPlayer extends StatelessWidget {
  final String videoUrl;

  const ScreenPlayer({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final ScreenPlayerController controller = Get.find<ScreenPlayerController>();
    controller.initializePlayer(videoUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isVideoInitialized.value || controller.isBuffering.value) {
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

        return Stack(
          children: [
            // Video Player covering full screen section
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.videoPlayerController!.value.size.width,
                  height: controller.videoPlayerController!.value.size.height,
                  child: VideoPlayer(controller.videoPlayerController!),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: controller.onScreenTapped,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Obx(() => controller.showControls.value
                ? Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Bar: 3-Dot Menu and Live/Go Live Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 20,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: controller.isLive.value ? Colors.red : const Color(0xFF8DBDCC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextButton(
                                  onPressed: controller.isLive.value
                                      ? null
                                      : () => controller.switchToLive(),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  child: Text(
                                    controller.isLive.value ? 'Live' : 'Go Live',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onSelected: (value) {
                                  if (value == 'Speed') {
                                    _showSpeedMenu(context);
                                  } else if (value == 'Quality') {
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
                          // Middle Controls: Forward/Backward
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                                onPressed: controller.seekBackward,
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: Icon(
                                  controller.videoPlayerController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                onPressed: controller.togglePlayPause,
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
                                onPressed: controller.seekForward,
                              ),
                            ],
                          ),
                          // Bottom Bar: Progress Bar or Live Indicator and Fullscreen
                          Column(
                            children: [
                              if (!controller.isLive.value) // Draggable progress bar for recorded videos
                                Slider(
                                  value: controller.videoPlayerController!.value.position.inSeconds.toDouble(),
                                  min: 0.0,
                                  max: controller.videoPlayerController!.value.duration.inSeconds.toDouble(),
                                  activeColor: Colors.red,
                                  inactiveColor: Colors.grey,
                                  onChanged: (value) {
                                    controller.videoPlayerController!.seekTo(Duration(seconds: value.toInt()));
                                  },
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  controller.isLive.value
                                      ? const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          '${controller.getPosition()} / ${controller.getDuration()}',
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                  IconButton(
                                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 30),
                                    onPressed: controller.toggleFullScreen,
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
        );
      }),
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
          onTap: () => controller.setQuality('https://mercyott.com/hls_output/master.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/360p.m3u8',
          child: const Text('360p'),
          onTap: () => controller.setQuality('https://mercyott.com/hls_output/360p.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/720p.m3u8',
          child: const Text('720p'),
          onTap: () => controller.setQuality('https://mercyott.com/hls_output/720p.m3u8'),
        ),
        PopupMenuItem(
          value: 'https://mercyott.com/hls_output/1080p.m3u8',
          child: const Text('1080p'),
          onTap: () => controller.setQuality('https://mercyott.com/hls_output/1080p.m3u8'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        controller.setQuality(value);
      }
    });
  }
}