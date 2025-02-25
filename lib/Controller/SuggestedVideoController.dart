import 'package:get/get.dart';
import 'package:mercy_tv_app/API/api_integration.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';

class SuggestedVideoController extends GetxController {
  var videoData = <dynamic>[].obs;
  var currentlyPlayingIndex = Rx<int?>(null);
  var isLoading = true.obs;
  var errorMessage = "".obs;

  late ScreenPlayerController playerController;

  @override
  void onInit() {
    playerController = Get.find<ScreenPlayerController>();
    fetchSortedVideoData();
    super.onInit();
  }

  Future<void> fetchSortedVideoData() async {
    try {
      isLoading.value = true;
      List<dynamic> data = await ApiIntegration().getVideoData();
      if (data.isNotEmpty) {
        data.sort((a, b) => int.parse(b['video_id']).compareTo(int.parse(a['video_id'])));
        videoData.assignAll(data);
      } else {
        errorMessage.value = "No video data received from API";
      }
    } catch (e) {
      errorMessage.value = "Error loading videos: $e";
    } finally {
      isLoading.value = false;
    }
  }

  void playVideo(String? videoUrl, int index) {
    if (videoUrl == null || videoUrl.isEmpty) {
      Get.snackbar("Error", "Invalid Video URL");
      return;
    }
    String fullUrl = videoUrl.startsWith('http') ? videoUrl : 'https://mercyott.com$videoUrl';
    bool isLive = fullUrl.contains(".m3u8");
    playerController.initializePlayer(fullUrl, live: isLive);
    currentlyPlayingIndex.value = index;
  }

  @override
  void onClose() {
    playerController.disposePlayer();
    super.onClose();
  }
}