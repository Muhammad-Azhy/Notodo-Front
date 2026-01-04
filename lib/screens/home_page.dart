import 'package:flutter/material.dart';
import 'package:front/Services/api_services.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/searchable_list.dart';
import 'problem_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService api = ApiService();
  List<Map<String, dynamic>> problems = [];

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  void _loadProblems() async {
    try {
      final fetchedProblems = await api.getProblems();
      setState(() => problems = fetchedProblems);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load problems")));
    }
  }

  void _addProblem() async {
    String title = '';
    String subtitle = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Problem"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Title"),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: "Subtitle (optional)",
              ),
              onChanged: (val) => subtitle = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (title.isEmpty) return;

              try {
                final newProblem = await api.createProblem(title, subtitle);

                setState(() {
                  problems.add({
                    "id": newProblem['id'],
                    "title": newProblem['title'],
                    "subtitle": newProblem['description'] ?? '',
                    "tasks": [],
                    "references": [],
                  });
                });

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to add problem")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Home"),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
      ),

      body: Column(
        children: [
          AppHeader(username: "Dante"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SearchableList<Map<String, dynamic>>(
                items: problems,
                titleSelector: (problem) => problem['title'],
                itemBuilder: (problem) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProblemDetailsPage(
                            problemId: problem['id'],
                            problemTitle: problem['title'],
                            problemSubtitle: problem['subtitle'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            problem['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          if ((problem['subtitle'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              problem['subtitle'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // ✅ FAB like ReferencesPage
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.sage,
        elevation: 2,
        onPressed: _addProblem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
