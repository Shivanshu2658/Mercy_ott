import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiIntegration {
  Future<List<dynamic>> getVideoData() async {
    final videoUrl = Uri.parse('https://mercyott.com/api/videoApi.php');

    try {
      final response = await http.get(videoUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      print('Error fetching video data: $e');
      return [];
    }
  }
}
