import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/API/api_integration.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';

class SuggestedVideoController extends GetxController {
  var videoData = <dynamic>[].obs;
  var currentlyPlayingIndex = 0.obs;
  var isLoading = true.obs;
  var errorMessage = "".obs;
  late ScrollController scrollController;
  late List<FocusNode> videoFocusNodes;
  bool _dataFetched = false;
  final RxInt lastFocusedIndex = 0.obs;
  final RxBool showSuggestedList = true.obs; // or false.obs initially

  @override
  void onInit() {
    scrollController = ScrollController();
    videoFocusNodes = [];
    if (!_dataFetched) {
      fetchSortedVideoData();
      _dataFetched = true;
      showSuggestedList.value = true;
    }
    super.onInit();
  }

  void hideSuggestedVideoList(bool visible) {
    showSuggestedList.value = visible;
    if (!visible) {
      Get.find<ScreenPlayerController>().showControls.value = false;
    }
  }

  Future<void> fetchSortedVideoData() async {
    try {
      debugPrint('Fetching video data...');
      isLoading.value = true;
      List<dynamic> data = await ApiIntegration().getVideoData();
      if (data.isNotEmpty) {
        data.sort((a, b) =>
            int.parse(b['video_id']).compareTo(int.parse(a['video_id'])));
        videoData.assignAll(data);
        videoFocusNodes = List.generate(
          videoData.length,
          (index) => FocusNode(debugLabel: 'SuggestedVideo_$index'),
        );
        debugPrint('Video data fetched: ${videoData.length} items');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.context != null && videoFocusNodes.isNotEmpty) {
            scrollController.jumpTo(0); // Ensure controller is attached

            FocusScope.of(Get.context!).requestFocus(videoFocusNodes[0]);
          }
        });
      } else {
        errorMessage.value = "No video data received from API";
        debugPrint('No video data received');
      }
    } catch (e) {
      errorMessage.value = "Error loading videos: $e";
      debugPrint('Error fetching video data: $e');
    } finally {
      isLoading.value = false;
      debugPrint('Loading complete, isLoading: ${isLoading.value}');
    }
  }

  final double cardWidth = 180 + 16; // Card width + margin
  bool get canMoveLeft => currentlyPlayingIndex.value > 0;
  bool get canMoveRight => currentlyPlayingIndex.value < videoData.length - 1;
  final _navigationLock = false.obs;

  void moveLeft() {
    if (!canMoveLeft || _navigationLock.value) return;
    _navigationLock.value = true;
    scrollToIndex(currentlyPlayingIndex.value - 1).then((_) {
      _navigationLock.value = false;
    });
  }

  void moveRight() {
    if (!canMoveRight || _navigationLock.value) return;
    _navigationLock.value = true;
    scrollToIndex(currentlyPlayingIndex.value + 1).then((_) {
      _navigationLock.value = false;
    });
  }

  // // Add this method to restore focus
  void restoreFocus() {
    if (lastFocusedIndex.value >= 0 &&
        lastFocusedIndex.value < videoFocusNodes.length) {
      videoFocusNodes[lastFocusedIndex.value].requestFocus();
      scrollToIndex(lastFocusedIndex.value);
    }
  }

  DateTime _lastScrollTime = DateTime.now();
  Duration scrollCooldown = const Duration(milliseconds: 400);

  Future<void> scrollToIndexThrottled(int index) async {
    final now = DateTime.now();
    if (now.difference(_lastScrollTime) < scrollCooldown) return;
    _lastScrollTime = now;
    await scrollToIndex(index, requestFocus: false);
  }

  Future<void> scrollToIndex(int index, {bool requestFocus = true}) async {
    if (index < 0 || index >= videoData.length) return;
    if (!scrollController.hasClients) {
      debugPrint('ScrollController not attached, cannot scroll');
      return;
    }

    currentlyPlayingIndex.value = index;
    lastFocusedIndex.value = index;

    final scrollPosition = index * cardWidth -
        (Get.context!.mediaQuerySize.width / 2) +
        (cardWidth / 2);

    await scrollController.animateTo(
      scrollPosition.clamp(0.0, scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
    );

    if (requestFocus && videoFocusNodes.length > index) {
      videoFocusNodes[index].requestFocus();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Restore focus when controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToIndex(currentlyPlayingIndex.value);
      // restoreFocus();
    });
  }

  /// shivanshu added this reset focus for resetting.
  void resetFocus() {
    currentlyPlayingIndex.value = 0;
    if (videoFocusNodes.isNotEmpty && Get.context != null) {
      FocusScope.of(Get.context!).requestFocus(videoFocusNodes[0]);
      debugPrint('Focus reset to index: 0');
      update();
      Get.forceAppUpdate();
    }
  }

  void playVideo(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) {
      Get.snackbar("Error", "Invalid Video URL");
      return;
    }
    String fullUrl = videoUrl.startsWith('http')
        ? videoUrl
        : 'https://mercyott.com$videoUrl';
    bool isLive = fullUrl.contains(".m3u8");
    Get.find<ScreenPlayerController>().initializePlayer(fullUrl, live: isLive);
    Get.find<ScreenPlayerController>().showControls.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ScreenPlayerController>().update();
      Get.forceAppUpdate();
    });
  }

  @override
  void onClose() {
    Get.find<ScreenPlayerController>().disposePlayer();
    scrollController.dispose();
    for (var node in videoFocusNodes) {
      node.dispose();
    }
    super.onClose();
  }
}
