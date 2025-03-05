import 'dart:async';
import 'package:get/get.dart';
import 'package:mercy_tv_app/API/dataModel.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';

class HomeController extends GetxController {
  var currentVideoUrl = 'https://mercyott.com/hls_output/master.m3u8'.obs;
  var isLiveStream = true.obs; // Start as live

  late ScreenPlayerController playerController;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    playerController = Get.find<ScreenPlayerController>();
    playerController.initializePlayer(currentVideoUrl.value, live: isLiveStream.value);
  }

  void playVideo(ProgramDetails programDetails) {
    if (programDetails.videoUrl == currentVideoUrl.value) return;

    currentVideoUrl.value = programDetails.videoUrl;
    isLiveStream.value = programDetails.videoUrl.contains(".m3u8");
    playerController.initializePlayer(currentVideoUrl.value, live: isLiveStream.value);
  }

  @override
  void onClose() {
    _timer?.cancel();
    playerController.disposePlayer();
    super.onClose();
  }
}