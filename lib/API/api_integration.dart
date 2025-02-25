import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiIntegration {
  Future<List<dynamic>> getVideoData() async {
    final videoUrl = Uri.parse('https://mercyott.com/api/videoApi.php');

    try {
      final response = await http.get(videoUrl);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else {
          debugPrint('API data is not a list');
          return [];
        }
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching video data: $e');
      return [];
    }
  }
}