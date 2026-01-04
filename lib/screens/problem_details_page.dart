import 'package:flutter/material.dart';
import 'package:front/screens/update_references_page.dart';
import 'package:front/screens/veiw_reference_page.dart';
import '../../theme/app_colors.dart';
import '../Services/api_services.dart';
import './Problem_Details/tasks_section.dart';
import './Problem_Details/references_section.dart';
import './new_reference_page.dart';

class ProblemDetailsPage extends StatefulWidget {
  final int problemId;
  final String? problemTitle;
  final String? problemSubtitle;

  const ProblemDetailsPage({
    super.key,
    required this.problemId,
    this.problemTitle,
    this.problemSubtitle,
  });

  @override
  State<ProblemDetailsPage> createState() => _ProblemDetailsPageState();
}

class _ProblemDetailsPageState extends State<ProblemDetailsPage> {
  final ApiService api = ApiService();
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _references = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      _tasks = await api.getTasks(problemId: widget.problemId);
      _references = await api.getReferences(problemId: widget.problemId);
      setState(() {});
    } catch (e) {
      print("Failed to load problem data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load problem data")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _addReference(String type) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewReferencePage(
          type: type,
          // initialType: type,
          // // initialProblem: widget.problemId.toString(),
          // // initialProblemId: widget.problemId,
          // // allProblems: [widget.problemId.toString()],
          // onCreate: (ref) {
          //   setState(() => _references.add(ref)); // <-- add new reference here
          // },
        ),
      ),
    );
  }

  Future<void> _updateReference(Map<String, dynamic> ref) async {
    final updatedRef = await Navigator.push(
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
    );

    if (updatedRef != null && updatedRef is Map<String, dynamic>) {
      final index = _references.indexWhere((r) => r['id'] == updatedRef['id']);
      if (index != -1) {
        setState(() => _references[index] = updatedRef);
      }
    }
  }

  Future<void> _deleteReference(int refId) async {
    try {
      await api.deleteReference(refId);
      setState(() => _references.removeWhere((r) => r['id'] == refId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete reference")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.problemTitle ?? "Problem"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium!.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.problemSubtitle != null)
              Text(
                widget.problemSubtitle!,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                ),
              ),
            const SizedBox(height: 24),
            TasksSection(problemId: widget.problemId),
            const SizedBox(height: 32),
            ReferencesSection(
              references: _references,
              onAdd: _addReference,
              onTap: _updateReference,
              // onUpdate: _updateReference,
              // onTap: (ref) {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) => ViewReferencePage(
              //         reference: ref,
              //         onUpdate: _updateReference,
              //         onDelete: () => _deleteReference(ref['id']),
              //       ),
              //     ),
              //   );
              // },
            ),
          ],
        ),
      ),
    );
  }
}
