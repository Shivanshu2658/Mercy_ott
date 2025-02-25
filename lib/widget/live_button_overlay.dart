import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

class CustomBetterPlayerControls extends StatelessWidget {
  final BetterPlayerController controller;

  const CustomBetterPlayerControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              controller.isPlaying() == true ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              if (controller.isPlaying() == true) {
                controller.pause();
              } else {
                controller.play();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () => controller.enterFullScreen(),
          ),
        ],
      ),
    );
  }
}