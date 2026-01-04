import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../theme/app_colors.dart';
import '../Services/api_services.dart';
import './new_reference_page.dart';
import './update_references_page.dart';

class ReferencesPage extends StatefulWidget {
  const ReferencesPage({super.key});

  @override
  State<ReferencesPage> createState() => _ReferencesPageState();
}

class _ReferencesPageState extends State<ReferencesPage> {
  final ApiService api = ApiService();

  List<Map<String, dynamic>> references = [];
  bool loading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    setState(() => loading = true);
    try {
      references = await api.getReferences();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load references: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _addReference(String type) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NewReferencePage(type: type)),
    );

    if (created == true) {
      await _loadReferences();
    }
  }

  void _editReference(Map<String, dynamic> ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateReferencePage(
          referenceId: ref['id'],
          initialType: ref['type'],
          initialTitle: ref['title'],
          initialContent: ref['content'],
          initialProblemId: ref['problem_id'],
        ),
      ),
    ).then((updatedRef) {
      if (updatedRef != null && updatedRef is Map<String, dynamic>) {
        final index = references.indexWhere((r) => r['id'] == updatedRef['id']);
        if (index != -1) {
          setState(() => references[index] = updatedRef);
        }
      }
    });
  }

  void _confirmDelete(Map<String, dynamic> ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Reference"),
        content: const Text("Are you sure you want to delete this reference?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteReference(ref);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReference(Map<String, dynamic> ref) async {
    try {
      await api.deleteReference(ref['id']);
      setState(() {
        references.removeWhere((r) => r['id'] == ref['id']);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  /// Converts quill JSON -> readable text
  String _renderTextContent(String? content) {
    if (content == null || content.isEmpty) return "";

    try {
      final decoded = jsonDecode(content);
      final doc = Document.fromJson(decoded);
      return doc.toPlainText().trim();
    } catch (_) {
      return content; // already plain text
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = references
        .where(
          (r) => (r['title'] ?? '').toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("All References"),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium!.color,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: "Search references...",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                      itemBuilder: (_, i) {
                        final ref = filtered[i];

                        return GestureDetector(
                          onTap: () => _editReference(ref),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ref['title'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium!.color,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmDelete(ref),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: ref['type'] == 'image'
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: ref['content'] != null
                                              ? kIsWeb
                                                    ? Image.network(
                                                        ref['content'],
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(ref['content']),
                                                        fit: BoxFit.cover,
                                                      )
                                              : Container(
                                                  color: Colors.grey[300],
                                                ),
                                        )
                                      : Text(
                                          _renderTextContent(ref['content']),
                                          maxLines: 6,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodySmall!.color,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.sage,
        elevation: 2,
        onPressed: () => _addReference("text"),
        child: const Icon(Icons.add),
      ),
    );
  }
}
