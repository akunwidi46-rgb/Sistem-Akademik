import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  const ApiClient();

  /// POST JSON and parse JSON response.
  ///
  /// Assumes backend returns JSON object or JSON array.
  Future<dynamic> postJson({
    required String url,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse(url);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final responseBody = response.body.trim();
    if (responseBody.isEmpty) {
      throw Exception('Server mengirim respons kosong');
    }

    // Some backends may send extra whitespace or JSON wrapped in text.
    // We keep a strict JSON decode here; callers rely on consistent backend.
    return jsonDecode(responseBody);
  }

  /// POST form fields and parse JSON response.
  Future<dynamic> postForm({
    required String url,
    required Map<String, String> body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse(url);
    final response = await http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(timeout);

    final responseBody = response.body.trim();
    if (responseBody.isEmpty) {
      throw Exception('Server mengirim respons kosong');
    }
    return jsonDecode(responseBody);
  }

  /// GET and parse JSON response.
  Future<dynamic> getJson({
    required String url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri).timeout(timeout);

    final responseBody = response.body.trim();
    if (responseBody.isEmpty) {
      throw Exception('Server mengirim respons kosong');
    }
    return jsonDecode(responseBody);
  }
}

