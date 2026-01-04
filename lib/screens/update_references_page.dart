import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../Services/api_services.dart';

class ProblemItem {
  final int id;
  final String title;

  ProblemItem({required this.id, required this.title});

  factory ProblemItem.fromJson(Map<String, dynamic> json) {
    return ProblemItem(id: json['id'], title: json['title']);
  }
}

class UpdateReferencePage extends StatefulWidget {
  final int referenceId;
  final String initialType;
  final String? initialTitle;
  final String? initialContent;
  final int? initialProblemId;

  const UpdateReferencePage({
    super.key,
    required this.referenceId,
    required this.initialType,
    this.initialTitle,
    this.initialContent,
    required this.initialProblemId,
  });

  @override
  State<UpdateReferencePage> createState() => _UpdateReferencePageState();
}

class _UpdateReferencePageState extends State<UpdateReferencePage> {
  final ApiService api = ApiService();
  List<ProblemItem> _allProblems = [];
  bool loadingProblems = true;

  final TextEditingController _titleController = TextEditingController();
  final QuillController _quillController = QuillController.basic();

  late String _type;
  int? _linkedProblemId;
  XFile? _pickedImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    _type = widget.initialType;
    _linkedProblemId = widget.initialProblemId;

    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }

    if (_type == "text" && widget.initialContent != null) {
      try {
        final delta = jsonDecode(widget.initialContent!);
        _quillController.document = Document.fromJson(delta);
      } catch (_) {
        _quillController.document.insert(0, widget.initialContent!);
      }
    }

    if (_type == "image" && widget.initialContent != null) {
      _pickedImage = XFile(widget.initialContent!);
    }
    _loadProblems();
  }

  Future<void> _loadProblems() async {
    try {
      final List<Map<String, dynamic>> raw = await api.getProblems();
      _allProblems = raw.map((p) => ProblemItem.fromJson(p)).toList();

      // If the initial linked problem exists, set it now
      if (widget.initialProblemId != null &&
          _allProblems.any((p) => p.id == widget.initialProblemId)) {
        _linkedProblemId = widget.initialProblemId;
      }
    } catch (e) {
      _showError("Failed to load problems");
    } finally {
      setState(() => loadingProblems = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _updateReference() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return _showError("Title is required");

    setState(() => loading = true);

    try {
      print({
        'id': widget.referenceId,
        'title': title,
        'type': _type,
        'problemId': _linkedProblemId,
      });

      await api.updateReference(
        widget.referenceId,
        title: title,
        type: _type,
        content: _type == "text"
            ? jsonEncode(_quillController.document.toDelta().toJson())
            : null,
        problemId: _linkedProblemId,

        //imageFile: _type == "image" ? _pickedImage : null,
      );

      Navigator.pop(context, {
        'id': widget.referenceId,
        'title': title,
        'type': _type,
        'content': _type == 'text'
            ? jsonEncode(_quillController.document.toDelta().toJson())
            : _pickedImage?.path,
        'problem_id': _linkedProblemId,
      });
      // notify parent to reload
    } catch (e) {
      _showError("Failed to update reference: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildContent() {
    if (_type == "text") {
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
      appBar: AppBar(title: const Text("Edit Reference"), elevation: 0),
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
            Text("hiiii"),
            Expanded(child: _buildContent()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _updateReference,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save Changessssss"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
