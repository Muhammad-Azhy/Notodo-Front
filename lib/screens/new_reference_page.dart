import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../Services/api_services.dart';
import 'package:http/http.dart' as http;

class ProblemItem {
  final int id;
  final String title;

  ProblemItem({required this.id, required this.title});

  factory ProblemItem.fromJson(Map<String, dynamic> json) {
    return ProblemItem(id: json['id'], title: json['title']);
  }
}

class NewReferencePage extends StatefulWidget {
  final String type; // "text" | "image"

  const NewReferencePage({super.key, required this.type});

  @override
  State<NewReferencePage> createState() => _NewReferencePageState();
}

class _NewReferencePageState extends State<NewReferencePage> {
  final ApiService api = ApiService();

  final TextEditingController _titleController = TextEditingController();
  final QuillController _quillController = QuillController.basic();

  List<ProblemItem> _allProblems = [];
  bool loadingProblems = true;

  int? _linkedProblemId;
  XFile? _pickedImage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  Future<void> _loadProblems() async {
    try {
      final List<Map<String, dynamic>> raw = await api.getProblems();
      _allProblems = raw.map((p) => ProblemItem.fromJson(p)).toList();
    } catch (_) {
      _showError("Failed to load problems");
    } finally {
      if (!mounted) return;
      setState(() => loadingProblems = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _saveReference() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError("Title is required");
      return;
    }

    setState(() => saving = true);

    try {
      http.Response res;
      final headers = await api.getHeaders();

      // IMAGE (MOBILE)
      if (widget.type == "image" &&
          !kIsWeb &&
          _pickedImage != null &&
          File(_pickedImage!.path).existsSync()) {
        final request = http.MultipartRequest(
          "POST",
          Uri.parse('${api.baseUrl}/references'),
        );

        request.headers.addAll(headers);
        request.fields['title'] = title;
        request.fields['type'] = 'image';

        if (_linkedProblemId != null) {
          request.fields['problem_id'] = _linkedProblemId.toString();
        }

        request.files.add(
          await http.MultipartFile.fromPath("image", _pickedImage!.path),
        );

        final streamed = await request.send();
        res = await http.Response.fromStream(streamed);
      } else {
        // TEXT OR WEB
        final body = {
          "title": title,
          "type": widget.type,
          "content": widget.type == "text"
              ? jsonEncode(_quillController.document.toDelta().toJson())
              : null,
          "problem_id": _linkedProblemId,
        };

        res = await http.post(
          Uri.parse('${api.baseUrl}/references'),
          headers: headers,
          body: jsonEncode(body),
        );
      }

      if (res.statusCode != 201) {
        throw "Error ${res.statusCode}";
      }

      if (!mounted) return;
      Navigator.pop(context, true); // parent reloads from backend
    } catch (_) {
      if (!mounted) return;
      _showError("Failed to create reference");
    } finally {
      if (!mounted) return;
      setState(() => saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildContent() {
    if (widget.type == "text") {
      return Column(
        children: [
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(controller: _quillController),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: const Text("Pick Image"),
        ),
        if (_pickedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: kIsWeb
                ? Image.network(_pickedImage!.path, height: 220)
                : Image.file(File(_pickedImage!.path), height: 220),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == "text" ? "New Text Reference" : "New Image Reference",
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _linkedProblemId,
              decoration: const InputDecoration(
                labelText: "Link to Problem (optional)",
                border: OutlineInputBorder(),
              ),
              items: loadingProblems
                  ? []
                  : _allProblems
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p.id,
                            child: Text(p.title),
                          ),
                        )
                        .toList(),
              onChanged: (val) => setState(() => _linkedProblemId = val),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _saveReference,
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save Reference"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
