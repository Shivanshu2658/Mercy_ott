// import 'package:flutter/material.dart';
// import 'package:better_player_plus/better_player_plus.dart';
//
// class VideoPlayerPage extends StatefulWidget {
//   const VideoPlayerPage({super.key});
//
//   @override
//   State<VideoPlayerPage> createState() => _VideoPlayerPageState();
// }
//
// class _VideoPlayerPageState extends State<VideoPlayerPage> {
//   late BetterPlayerController _betterPlayerController;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideoPlayer();
//   }
//
//   void _initializeVideoPlayer() {
//     final BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8', // Replace with your m3u8 URL
//       videoFormat: BetterPlayerVideoFormat.hls, // Important for m3u8
//     );
//
//     _betterPlayerController = BetterPlayerController(
//       const BetterPlayerConfiguration(
//         autoPlay: true,
//         aspectRatio: 16 / 9,
//         fit: BoxFit.contain,
//       ),
//       betterPlayerDataSource: dataSource,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('HLS Video Player')),
//       body: Center(
//         child: BetterPlayer(controller: _betterPlayerController),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _betterPlayerController.dispose();
//     super.dispose();
//   }
// }
