import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class AnalyzeApi {
  // Uses live API in production (TestFlight/App Store), and localhost for active development
  static const String _baseUrl = kReleaseMode 
      ? 'https://api.smartsurf.app'
      : 'http://localhost:8000';

  static Future<Map<String, dynamic>> uploadAndAnalyze(
    XFile videoFile, {
    required Function(double) onProgress,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/analyze_popup');
    final request = http.MultipartRequest('POST', uri);

    final fileLength = await videoFile.length();

    // Custom multipart file that tracks progress
    final multipartFile = http.MultipartFile(
      'video',
      videoFile.readAsBytes().asStream().map((chunk) {
        // Unfortunately standard http package doesn't natively expose upload progress.
        // For a more robust solution we would use dio, but with http we can simulate
        // progress if we read it into memory, or we just trust the underlying stream.
        return chunk;
      }),
      fileLength,
      filename: videoFile.name,
    );

    request.files.add(multipartFile);

    try {
      // Create a client to send the stream
      final client = http.Client();
      
      // Simulate progress for the UI since http doesn't give us native byte-level callbacks easily without a custom ByteStream adapter.
      // We'll increment progress gradually while waiting for the response.
      bool isDone = false;
      _simulateProgress(onProgress, () => isDone);
      
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 90));
      isDone = true;
      onProgress(1.0); // complete

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 413) {
        throw Exception('File exceeds maximum size of 50MB');
      } else {
        throw Exception('Failed to analyze video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeReflection({
    required String focus,
    required String workedOn,
    required String feltHard,
    required String feltGood,
    required String conditions,
    required String notes,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/analyze_reflection');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'focus': focus,
          'worked_on': workedOn,
          'felt_hard': feltHard,
          'felt_good': feltGood,
          'conditions': conditions,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 15)); // Fast timeout since we have a robust UI fallback

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Reflection request failed: $e');
    }
  }

  static void _simulateProgress(Function(double) onProgress, bool Function() isDone) async {
    double progress = 0.0;
    while (!isDone() && progress < 0.9) {
      // Slowly increment up to 90%, the final 10% is parsing the response
      await Future.delayed(const Duration(milliseconds: 500));
      progress += 0.05;
      if (progress > 0.9) progress = 0.9;
      onProgress(progress);
    }
  }
}
