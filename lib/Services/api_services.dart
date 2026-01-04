import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = 'http://127.0.0.1:8000/api';
  String? _token;

  // ================= TOKEN =================
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // ================= HEADERS =================
  Future<Map<String, String>> getHeaders() async {
    if (_token == null) await loadToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  // ================= AUTH =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null)
      await setToken(data['token']);
    return data;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null)
      await setToken(data['token']);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: await getHeaders(),
    );
    return jsonDecode(res.body);
  }
  // ================= USER (SELF CRUD) =================

  Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: await getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch profile: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    // Backend uses: password + password_confirmation (confirmed rule)
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation ?? '';
    }

    final res = await http.put(
      Uri.parse('$baseUrl/user'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update profile: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<void> deleteAccount({required String password}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/user'),
      headers: await getHeaders(),
      body: jsonEncode({'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete account: ${res.body}');
    }

    // Optional: clear token locally after delete
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  Future<void> logout() async {
    // optional if your backend supports POST /logout
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await getHeaders(),
      );
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // ================= PROBLEMS =================
  Future<List<Map<String, dynamic>>> getProblems() async {
    final res = await http.get(
      Uri.parse('$baseUrl/problems'),
      headers: await getHeaders(),
    );
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProblem(
    String title,
    String? description,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/problems'),
      headers: await getHeaders(),
      body: jsonEncode({'title': title, 'description': description}),
    );
    if (res.statusCode != 201) throw Exception('Failed to create problem');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getProblem(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/problems/$id'),
      headers: await getHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to fetch problem');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateProblem(
    int id, {
    String? title,
    String? description,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/problems/$id'),
      headers: await getHeaders(),
      body: jsonEncode({'title': title, 'description': description}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update problem');
    return jsonDecode(res.body);
  }

  Future<void> deleteProblem(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/problems/$id'),
      headers: await getHeaders(),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete problem');
  }

  // ================= TASKS =================
  Future<List<Map<String, dynamic>>> getTasks({int? problemId}) async {
    // Build the correct URI
    final uri = problemId != null
        ? Uri.parse('$baseUrl/problems/$problemId/tasks')
        : Uri.parse('$baseUrl/tasks');

    final res = await http.get(uri, headers: await getHeaders());
    if (res.statusCode >= 400) {
      throw Exception('Failed to fetch tasks');
    }

    final data = jsonDecode(res.body) as List<dynamic>;

    // Fetch all problems to get their titles
    final problemsRes = await http.get(
      Uri.parse('$baseUrl/problems'),
      headers: await getHeaders(),
    );
    if (problemsRes.statusCode >= 400) {
      throw Exception('Failed to fetch problems');
    }
    final problemsList = (jsonDecode(problemsRes.body) as List<dynamic>)
        .map<Map<String, dynamic>>(
          (p) => {'id': p['id'], 'title': p['title'] ?? 'Unknown'},
        )
        .toList();

    // Map problem_id to problem title for quick lookup
    final problemTitles = {for (var p in problemsList) p['id']: p['title']};

    // Normalize each task
    return data.map<Map<String, dynamic>>((t) {
      final map = t as Map<String, dynamic>;
      final pid = map['problem_id'] ?? 0;
      return {
        'id': map['id'],
        'title': map['title'] ?? '',
        'done': map['done'] == 1 || map['done'] == true,
        'problem_id': pid,
        'problem_title': problemTitles[pid] ?? 'Unknown',
      };
    }).toList();
  }

  Future<Map<String, dynamic>> createTask(String title, int problemId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: await getHeaders(),
      body: jsonEncode({'title': title, 'problem_id': problemId}),
    );
    if (res.statusCode != 201) throw Exception('Failed to create task');
    final data = jsonDecode(res.body);
    // Ensure done is bool
    return {...data, 'done': data['done'] == 1 || data['done'] == true};
  }

  Future<Map<String, dynamic>> updateTask(
    int taskId, {
    String? title,
    bool? done,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: await getHeaders(),
      body: jsonEncode({'title': title, 'done': done}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update task');
    final data = jsonDecode(res.body);
    return {...data, 'done': data['done'] == 1 || data['done'] == true};
  }

  Future<void> deleteTask(int taskId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: await getHeaders(),
    );
  }

  // ================= REFERENCES =================
  Future<List<Map<String, dynamic>>> getReferences({int? problemId}) async {
    if (problemId == null) {
      final uri = Uri.parse('$baseUrl/references');
      final res = await http.get(uri, headers: await getHeaders());
      if (res.statusCode != 200) throw Exception('Failed to fetch references');
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    final uri = Uri.parse('$baseUrl/problems/$problemId/references');

    final res = await http.get(uri, headers: await getHeaders());
    if (res.statusCode != 200) throw Exception('Failed to fetch references');
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createReference({
    required String title,
    required String type,
    String? content,
    int? problemId,
    XFile? imageFile,
  }) async {
    final headers = await getHeaders();

    if (type == "image" && imageFile != null) {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse('$baseUrl/references'),
      );
      request.headers.addAll(headers);
      request.fields["title"] = title;
      request.fields["type"] = type;
      if (problemId != null)
        request.fields["problem_id"] = problemId.toString();

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            bytes,
            filename: imageFile.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile.path),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 201) throw "Error ${res.statusCode}: ${res.body}";
      return jsonDecode(res.body);
    }

    final res = await http.post(
      Uri.parse('$baseUrl/references'),
      headers: headers,
      body: jsonEncode({
        "title": title,
        "type": type,
        "content": content,
        "problem_id": problemId,
      }),
    );
    if (res.statusCode != 201) throw "Error ${res.statusCode}: ${res.body}";
    return jsonDecode(res.body);
  }

  Future<void> updateReference(
    int id, {
    required String title,
    required String type,
    String? content,
    int? problemId,
  }) async {
    final headers = await getHeaders();

    final res = await http.put(
      Uri.parse('$baseUrl/references/$id'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'type': type,
        'content': content,
        'problem_id': problemId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Update failed: ${res.body}');
    }
  }

  Future<void> deleteReference(int refId) async {
    print('Deleting reference with id $refId');
    final res = await http.delete(
      Uri.parse('$baseUrl/references/$refId'),
      headers: await getHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to delete reference');
  }

  // ================= ATTACHMENTS =================
  Future<List<Map<String, dynamic>>> getAttachments({int? problemId}) async {
    final uri = Uri.parse(
      '$baseUrl/attachments${problemId != null ? '?problem_id=$problemId' : ''}',
    );
    final res = await http.get(uri, headers: await getHeaders());
    if (res.statusCode != 200) throw Exception('Failed to fetch attachments');
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAttachment({
    required String name,
    int? problemId,
    XFile? file,
  }) async {
    final headers = await getHeaders();
    var request = http.MultipartRequest(
      "POST",
      Uri.parse('$baseUrl/attachments'),
    );
    request.headers.addAll(headers);
    request.fields["name"] = name;
    if (problemId != null) request.fields["problem_id"] = problemId.toString();

    if (file != null) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes("file", bytes, filename: file.name),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath("file", file.path));
      }
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) throw "Error ${res.statusCode}: ${res.body}";
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateAttachment(
    int attId, {
    String? name,
    int? problemId,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/attachments/$attId'),
      headers: await getHeaders(),
      body: jsonEncode({'name': name, 'problem_id': problemId}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update attachment');
    return jsonDecode(res.body);
  }

  Future<void> deleteAttachment(int attId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attachments/$attId'),
      headers: await getHeaders(),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete attachment');
  }
}
