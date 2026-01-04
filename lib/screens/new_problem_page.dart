import 'package:flutter/material.dart';
import '../Services/api_services.dart';

class NewProblemPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreate;

  const NewProblemPage({super.key, required this.onCreate});

  @override
  State<NewProblemPage> createState() => _NewProblemPageState();
}

class _NewProblemPageState extends State<NewProblemPage> {
  final ApiService api = ApiService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();

  bool loading = false;

  Future<void> _createProblem() async {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    setState(() => loading = true);

    try {
      final problem = await api.createProblem(
        title,
        subtitle.isEmpty ? null : subtitle,
      );

      // Normalize response so UI always gets what it expects
      widget.onCreate({
        "id": problem["id"],
        "title": problem["title"],
        "subtitle": problem["description"] ?? "",
        "tasks": [],
        "references": [],
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to create problem: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Problem"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium!.color,
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
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: "Subtitle",
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _createProblem,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create Problem"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
