import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/widget/button_section.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/widget/sugested_video_list.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isFavorite = false;
  Timer? _timer;
  DateTime _currentDateTime = DateTime.now();
  String _currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8';
  bool _isLiveStream = true;
  String _selectedProgramTitle = 'Mercy TV Live';
  String _selectedProgramDate = '';
  String _selectedProgramTime = '';
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableProgressText: true,
          enablePlaybackSpeed: true,
        ),
      ),
    );
    
    _loadVideo(_currentVideoUrl);  // Load the HLS stream URL
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _loadVideo(String url) {
    _betterPlayerController.setupDataSource(BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      cacheConfiguration: const BetterPlayerCacheConfiguration(
        useCache: true,
      ),
    )).catchError((e) {
      // Handle the error gracefully, possibly show a fallback message
      print("Error loading video: $e");
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _betterPlayerController.dispose();
    super.dispose();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://mercytv.tv/support-ott/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _playVideo(ProgramDetails programDetails) {
    if (!mounted) return;
    setState(() {
      _currentVideoUrl = programDetails.videoUrl;
      _isLiveStream = false;
      _selectedProgramTitle = programDetails.title;

      if (programDetails.date != null && programDetails.date!.isNotEmpty) {
        try {
          DateTime parsedDate =
              DateFormat('yyyy-MM-dd').parse(programDetails.date!);
          _selectedProgramDate = DateFormat('EEE dd MMM').format(parsedDate);
        } catch (e) {
          _selectedProgramDate = programDetails.date!;
        }
      } else {
        _selectedProgramDate = '';
      }

      if (programDetails.time != null && programDetails.time!.isNotEmpty) {
        try {
          DateTime parsedTime =
              DateFormat('HH:mm:ss').parse(programDetails.time!);
          _selectedProgramTime = DateFormat('hh:mm a').format(parsedTime);
        } catch (e) {
          _selectedProgramTime = programDetails.time!;
        }
      } else {
        _selectedProgramTime = '';
      }

      // Load the new video URL
      _loadVideo(_currentVideoUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = _selectedProgramDate.isNotEmpty
        ? _selectedProgramDate
        : DateFormat('EEE dd MMM').format(_currentDateTime);
    String formattedTime = _selectedProgramTime.isNotEmpty
        ? _selectedProgramTime
        : DateFormat('hh:mm a').format(_currentDateTime);

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
            SizedBox(
              height: 250,
              child: BetterPlayer(
                controller: _betterPlayerController,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: GestureDetector(
                              child: Text(
                                _selectedProgramTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Mulish-Bold'
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15,
                                fontFamily: 'Mulish-Medium'),
                                 
                          ),
                          const SizedBox(width: 8),
                          const Text("|",
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 8),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const ButtonSection(),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _launchURL,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Center(
                            child: Text(
                              'Sponsor us',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Mulish-Medium'
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Past Programs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Mulish-Medium'
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 138,
                        height: 2,
                        color: CustomColors.buttonColor,
                      ),
                      SuggestedVideoCard(
                        onVideoTap: _playVideo,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
