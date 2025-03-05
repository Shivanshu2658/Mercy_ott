import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/Controller/home_controller.dart';
import 'package:mercy_tv_app/Controller/screenplayer_controller.dart';
import 'package:mercy_tv_app/Controller/SuggestedVideoController.dart';
import 'package:mercy_tv_app/Screens/Splash_screen.dart';

void main() {
  Get.put(SuggestedVideoController()); // Initialize first
  Get.put(ScreenPlayerController());   // Then ScreenPlayerController, which depends on SuggestedVideoController
  Get.put(HomeController());           // Finally HomeController

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}