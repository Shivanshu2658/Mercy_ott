// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';
// import 'package:mercy_tv_app/Controller/SuggestedVideoController.dart';
// import 'package:video_player/video_player.dart';
//
// class ScreenPlayer extends StatelessWidget {
//   final String videoUrl;
//   final ScreenPlayerController controller = Get.find<ScreenPlayerController>();
//   final SuggestedVideoController suggestedController = Get.find<SuggestedVideoController>();
//
//   ScreenPlayer({super.key, required this.videoUrl});
//
//   @override
//   Widget build(BuildContext context) {
//     controller.initializePlayer(videoUrl);
//
//     return Scaffold(
//       backgroundColor: Colors.grey[900],
//       body: RawKeyboardListener(
//         focusNode: FocusNode()..requestFocus(),
//         onKey: controller.handleKeyEvent,
//         child: Stack(
//           children: [
//             SizedBox.expand(
//               child: Obx(() {
//                 if (!controller.isVideoInitialized.value || controller.isBuffering.value) {
//                   return Container(
//                     color: Colors.grey[900],
//                     child: const Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(color: Colors.white),
//                           SizedBox(height: 16),
//                           Text(
//                             'Loading video...',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }
//                 return FittedBox(
//                   fit: BoxFit.cover,
//                   child: SizedBox(
//                     width: controller.videoPlayerController!.value.size.width,
//                     height: controller.videoPlayerController!.value.size.height,
//                     child: VideoPlayer(controller.videoPlayerController!),
//                   ),
//                 );
//               }),
//             ),
//             GestureDetector(
//               onTap: controller.onScreenTapped,
//               behavior: HitTestBehavior.opaque,
//               child: Obx(() => AnimatedOpacity(
//                     opacity: controller.showControls.value ? 1.0 : 0.0,
//                     duration: const Duration(milliseconds: 300),
//                     child: Container(
//                       color: Colors.black54,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Focus(
//                                   focusNode: controller.liveButtonFocus,
//                                   onFocusChange: (hasFocus) {
//                                     controller.isLiveButtonFocused.value = hasFocus;
//                                     if (hasFocus) controller.update();
//                                   },
//                                   child: Obx(() => GestureDetector(
//                                         onTap: controller.isLive.value ? null : controller.switchToLive,
//                                         child: AnimatedContainer(
//                                           duration: const Duration(milliseconds: 200),
//                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                           decoration: BoxDecoration(
//                                             color: controller.isLive.value
//                                                 ? Colors.red
//                                                 : const Color(0xFF8DBDCC),
//                                             borderRadius: BorderRadius.circular(20),
//                                             border: controller.liveButtonFocus.hasFocus
//                                                 ? Border.all(color: Colors.yellow, width: 2)
//                                                 : null,
//                                           ),
//                                           child: Text(
//                                             controller.isLive.value ? 'Live' : 'Go Live',
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 11,
//                                             ),
//                                           ),
//                                         ),
//                                       )),
//                                 ),
//                                 Focus(
//                                   focusNode: controller.menuButtonFocus,
//                                   onFocusChange: (hasFocus) {
//                                     controller.isTopBarFocused.value = hasFocus;
//                                     if (hasFocus) controller.update();
//                                   },
//                                   child: Obx(() => GestureDetector(
//                                         onTap: () => controller.showPopupMenu(context),
//                                         child: AnimatedContainer(
//                                           duration: const Duration(milliseconds: 200),
//                                           padding: const EdgeInsets.all(8),
//                                           decoration: BoxDecoration(
//                                             border: controller.menuButtonFocus.hasFocus
//                                                 ? Border.all(color: Colors.yellow, width: 2)
//                                                 : null,
//                                             borderRadius: BorderRadius.circular(20),
//                                           ),
//                                           child: const Icon(
//                                             Icons.more_vert,
//                                             color: Colors.white,
//                                           ),
//                                         ),
//                                       )),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Obx(() => suggestedController.isLoading.value
//                               ? const SizedBox.shrink()
//                               : Container(
//                                   height: 100,
//                                   padding: const EdgeInsets.symmetric(vertical: 8),
//                                   child: ListView.builder(
//                                     controller: suggestedController.scrollController,
//                                     scrollDirection: Axis.horizontal,
//                                     itemCount: suggestedController.videoData.length,
//                                     itemBuilder: (context, index) {
//                                       final video = suggestedController.videoData[index];
//                                       return Focus(
//                                         focusNode: suggestedController.videoFocusNodes[index],
//                                         onFocusChange: (hasFocus) {
//                                           if (hasFocus) {
//                                             suggestedController.currentlyPlayingIndex.value = index;
//                                             controller.update();
//                                             suggestedController.update();
//                                           }
//                                         },
//                                         child: GestureDetector(
//                                           onTap: () => suggestedController.playVideo(video['video_url']),
//                                           child: AnimatedContainer(
//                                             duration: const Duration(milliseconds: 200),
//                                             width: 180,
//                                             margin: const EdgeInsets.symmetric(horizontal: 8),
//                                             decoration: BoxDecoration(
//                                               color: Colors.grey[800],
//                                               borderRadius: BorderRadius.circular(8),
//                                               border: suggestedController.videoFocusNodes[index].hasFocus
//                                                   ? Border.all(color: Colors.yellow, width: 2)
//                                                   : null,
//
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 video['title'] ?? 'Video $index',
//                                                 style: const TextStyle(color: Colors.white),
//                                                 textAlign: TextAlign.center,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 )),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.replay_10,
//                                           color: Colors.white, size: 40),
//                                       onPressed: controller.seekBackwardWithFeedback,
//                                     ),
//                                     const SizedBox(width: 20),
//                                     IconButton(
//                                       icon: Icon(
//                                         controller.videoPlayerController!.value.isPlaying
//                                             ? Icons.pause
//                                             : Icons.play_arrow,
//                                         color: Colors.white,
//                                         size: 40,
//                                       ),
//                                       onPressed: controller.togglePlayPause,
//                                     ),
//                                     const SizedBox(width: 20),
//                                     IconButton(
//                                       icon: const Icon(Icons.forward_10,
//                                           color: Colors.white, size: 40),
//                                       onPressed: controller.seekForwardWithFeedback,
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 if (!controller.isLive.value)
//                                   Slider(
//                                     value: controller.videoPlayerController!.value.position.inSeconds.toDouble(),
//                                     min: 0.0,
//                                     max: controller.videoPlayerController!.value.duration.inSeconds.toDouble(),
//                                     activeColor: Colors.red,
//                                     inactiveColor: Colors.grey,
//                                     onChanged: (value) {
//                                       controller.videoPlayerController!
//                                           .seekTo(Duration(seconds: value.toInt()));
//                                     },
//                                   ),
//                                 const SizedBox(height: 8),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     controller.isLive.value
//                                         ? const Text(
//                                             'LIVE',
//                                             style: TextStyle(
//                                               color: Colors.red,
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           )
//                                         : Text(
//                                             '${controller.getPosition()} / ${controller.getDuration()}',
//                                             style: const TextStyle(color: Colors.white, fontSize: 16),
//                                           ),
//                                     IconButton(
//                                       icon: const Icon(Icons.fullscreen,
//                                           color: Colors.white, size: 30),
//                                       onPressed: controller.toggleFullScreen,
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )),
//             ),
//             Obx(() => controller.showSeekFeedback.value
//                 ? Center(
//                     child: AnimatedOpacity(
//                       opacity: controller.showSeekFeedback.value ? 1.0 : 0.0,
//                       duration: const Duration(milliseconds: 300),
//                       child: Text(
//                         controller.seekFeedbackText.value,
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   )
//                 : const SizedBox.shrink()),
//           ],
//         ),
//       ),
//     );
//   }
// }