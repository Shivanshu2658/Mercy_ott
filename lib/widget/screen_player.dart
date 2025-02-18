import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isLiveStream;

  const ScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.isLiveStream,
  });

  @override
  ScreenPlayerState createState() => ScreenPlayerState();
}

class ScreenPlayerState extends State<ScreenPlayer>
    with WidgetsBindingObserver {
  BetterPlayerController? _betterPlayerController;
  bool _isVideoInitialized = false;
  bool _isDisposed = false;
  bool _isLiveStream = false;
  bool _showButton = false;
  Timer? _hideButtonTimer;
  int _playerInitToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer(widget.videoUrl, widget.isLiveStream);
  }

  @override
  void didUpdateWidget(covariant ScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.isLiveStream != widget.isLiveStream) {
      _initializePlayer(widget.videoUrl, widget.isLiveStream);
    }
  }

  Future<void> _initializePlayer(String videoUrl, bool isLiveStream) async {
    _disposeControllers();
    final int currentToken = ++_playerInitToken;

    try {
      final BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        liveStream: _isLiveStream,
        videoFormat: BetterPlayerVideoFormat.hls,
        useAsmsTracks: true,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/vnd.apple.mpegurl',
          'Connection': 'keep-alive',
        },
      );

      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          aspectRatio: 16 / 9,
          autoPlay: true,
          looping: false,         
          fullScreenByDefault: false,
          handleLifecycle: true,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enablePlayPause: true,
            enableFullscreen: true,
            enableSkips: false,
          ),
        ),
        betterPlayerDataSource: dataSource,
      );

      await controller.setupDataSource(dataSource);

      if (mounted && !_isDisposed && currentToken == _playerInitToken) {
        _betterPlayerController = controller;
        _isLiveStream = isLiveStream;
        _isVideoInitialized = true;

        if (isLiveStream) {
          _betterPlayerController!.play();
        }

        setState(() {});
      }
    } catch (e) {
      if (mounted && currentToken == _playerInitToken) {
        _isVideoInitialized = false;
        setState(() {});
      }
      debugPrint('Error initializing video: $e');
      _showErrorDialog('Error initializing video. Please try again later.');
    }
  }

  void _disposeControllers() {
    _betterPlayerController?.dispose();
    _betterPlayerController = null;
    _isVideoInitialized = false;
  }

  void _onScreenTapped() {
    setState(() {
      _showButton = true;
    });
    _hideButtonTimer?.cancel();
    _hideButtonTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isDisposed) {
        setState(() => _showButton = false);
      }
    });
  }

  void _showErrorDialog(String message) {
    if (!_isDisposed && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _disposeControllers();
    _hideButtonTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;

    if (_betterPlayerController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isFullScreen = _betterPlayerController!.isFullScreen;
        if (orientation == Orientation.landscape && !isFullScreen) {
          _betterPlayerController!.enterFullScreen();
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else if (orientation == Orientation.portrait && isFullScreen) {
          _betterPlayerController!.exitFullScreen();
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isVideoInitialized && _betterPlayerController != null
              ? BetterPlayer(controller: _betterPlayerController!)
              : const Center(child: CircularProgressIndicator()),
          GestureDetector(
            onTap: _onScreenTapped,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          if (_showButton)
            Positioned(
              top: 22,
              left: 16,
              child: _liveButton(
                _isLiveStream ? 'Live' : 'Go Live',
                _isLiveStream ? Colors.red : const Color(0xFF8DBDCC),
                () => _initializePlayer(
                  'https://mercyott.com/hls_output/master.m3u8',
                  false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _liveButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 24),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
