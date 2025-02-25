import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';

class HomeController extends GetxController {
  var isFavorite = false.obs;
  var currentDateTime = DateTime.now().obs;
  var currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8'.obs;
  var isLiveStream = true.obs; // Default to live
  var selectedProgramTitle = 'Mercy TV Live'.obs;
  var selectedProgramDate = ''.obs;
  var selectedProgramTime = ''.obs;

  late ScreenPlayerController playerController;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    playerController = Get.find<ScreenPlayerController>();
    _startTimer();
    playerController.initializePlayer(currentVideoUrl.value, live: isLiveStream.value);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentDateTime.value = DateTime.now();
    });
  }

  void playVideo(ProgramDetails programDetails) {
    if (programDetails.videoUrl == currentVideoUrl.value) return;

    currentVideoUrl.value = programDetails.videoUrl;
    isLiveStream.value = programDetails.videoUrl.contains(".m3u8");
    selectedProgramTitle.value = programDetails.title;

    if (programDetails.date != null && programDetails.date!.isNotEmpty) {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(programDetails.date!);
      selectedProgramDate.value = DateFormat('EEE dd MMM').format(parsedDate);
    } else {
      selectedProgramDate.value = '';
    }

    if (programDetails.time != null && programDetails.time!.isNotEmpty) {
      DateTime parsedTime = DateFormat('HH:mm:ss').parse(programDetails.time!);
      selectedProgramTime.value = DateFormat('hh:mm a').format(parsedTime);
    } else {
      selectedProgramTime.value = '';
    }

    playerController.initializePlayer(currentVideoUrl.value, live: isLiveStream.value);
  }

  @override
  void onClose() {
    _timer?.cancel();
    playerController.disposePlayer();
    super.onClose();
  }
}