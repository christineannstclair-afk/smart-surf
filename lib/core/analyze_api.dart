import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class AnalyzeApi {
  // Uses live API in production (TestFlight/App Store)
  static const String _baseUrl = 'https://smart-surf-backend.onrender.com';
  
  // ZERO-SPEND TEST MODE: Flip to TRUE to test UI limits without spending AI tokens.
  // Flip to FALSE for production.
  static const bool isTestMode = false;

  static Future<Map<String, dynamic>> uploadAndAnalyze(
    XFile videoFile, {
    required String idToken,
    required String sessionId,
    required Function(double) onProgress,
  }) async {
    if (isTestMode) {
      await Future.delayed(const Duration(seconds: 2));
      onProgress(1.0);
      return {
        "confidence_score": 0.85,
        "metrics": {"popup_time_seconds": 1.2, "knee_angle_min": 115, "stance_width_ratio": 1.1, "back_angle_at_stand": 45, "stability_score": 88},
        "feedback": {"looks_solid": true, "primary_improvement": "Great job! Your pop-up is fast.", "drill_to_practice": "Practice your bottom turn now."},
        "note": "MOCK RESPONSE (ZERO SPEND)"
      };
    }

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

    request.headers['Authorization'] = 'Bearer $idToken';
    request.fields['session_id'] = sessionId;
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
      } else if (response.statusCode == 429) {
        debugPrint("AnalyzeApi: DAILY LIMIT REACHED ✖ (HTTP 429)");
        throw Exception('DAILY_LIMIT_REACHED');
      } else {
        throw Exception('Failed to analyze video: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("AnalyzeApi: REQUEST FAILED: $e");
      if (e.toString().contains('DAILY_LIMIT_REACHED')) {
        throw Exception('DAILY_LIMIT_REACHED');
      }
      throw Exception('Analysis failed: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeReflection({
    required String idToken,
    required String sessionId,
    required String focus,
    required String workedOn,
    required String feltHard,
    required String feltGood,
    required String conditions,
    required String notes,
    required String language,
    String? waveHeight,
    String? board,
  }) async {
    if (isTestMode) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        "session_insight_en": "It sounds like you had some good moments out there — the wave selection is feeling more natural. The timing of the pop-up still seems a bit hit or miss, which is super normal at this stage.",
        "progress_pattern_en": "Feels like things are starting to click, just not quite all at once yet.",
        "next_session_focus_en": "Next time, try popping up a touch earlier and see how that feels.",
        "session_insight_es": "Parece que tuviste buenos momentos — la selección de olas se está sintiendo más natural. El timing del pop-up todavía parece un poco variable, lo cual es muy normal en esta etapa.",
        "progress_pattern_es": "Parece que las cosas están empezando a encajar, solo que no del todo a la vez.",
        "next_session_focus_es": "La próxima vez, intenta levantarte un poco antes y fíjate cómo se siente.",
        "focus_tag_en": "POP-UP TIMING",
        "focus_tag_es": "TIMING DE DESPEGUE",
        "note": "MOCK RESPONSE (ZERO SPEND)"
      };
    }

    final uri = Uri.parse('$_baseUrl/api/analyze_reflection');
    
    try {
      debugPrint("AnalyzeApi: CALLING REAL AI BACKEND for reflection...");
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'focus': focus,
          'worked_on': workedOn,
          'felt_hard': feltHard,
          'felt_good': feltGood,
          'conditions': conditions,
          'notes': notes,
          'language': language,
          'wave_height': waveHeight,
          'board': board,
        }),
      ).timeout(const Duration(seconds: 30)); 

      debugPrint("AnalyzeApi: Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        debugPrint("AnalyzeApi: SUCCESS ✔");
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        debugPrint("AnalyzeApi: AUTH ERROR ✖ (401)");
        final body = jsonDecode(response.body);
        final detail = body['detail'] ?? 'AUTH_EXPIRED';
        throw Exception('AUTH_ERROR: $detail');
      } else if (response.statusCode == 403) {
        debugPrint("AnalyzeApi: PAYWALL REQUIRED ✖ (403)");
        final body = jsonDecode(response.body);
        if (body['detail'] != null && body['detail']['error'] == 'paywall_required') {
          throw Exception('PAYWALL_REQUIRED');
        }
        throw Exception('PAYWALL_REQUIRED');
      } else if (response.statusCode == 429) {
        debugPrint("AnalyzeApi: DAILY LIMIT REACHED ✖ (429)");
        throw Exception('DAILY_LIMIT_REACHED');
      } else {
        debugPrint("AnalyzeApi: BACKEND ERROR ${response.statusCode} ✖");
        throw Exception('BACKEND_ERROR_${response.statusCode}');
      }
    } catch (e) {
      debugPrint("AnalyzeApi: REQUEST FAILED: $e");
      if (e.toString().contains('AUTH_ERROR')) throw Exception(e.toString());
      if (e.toString().contains('PAYWALL_REQUIRED')) throw Exception('PAYWALL_REQUIRED');
      if (e.toString().contains('DAILY_LIMIT_REACHED')) throw Exception('DAILY_LIMIT_REACHED');
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
