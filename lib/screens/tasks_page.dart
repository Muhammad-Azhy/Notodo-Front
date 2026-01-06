import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../Services/api_services.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final ApiService api = ApiService();

  List<Map<String, dynamic>> tasks = [];
  bool loading = true;

  String searchQuery = '';
  String selectedProblem = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => loading = true);
    try {
      final fetched = await api.getTasks();
      tasks = fetched.map<Map<String, dynamic>>((t) {
        return {
          'id': t['id'],
          'title': t['title'] ?? '',
          'done': t['done'] == true || t['done'] == 1,
          'problem_id': t['problem_id'],
          'problem_title': t['problem_title'] ?? 'None',
        };
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load tasks: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filteredTasks {
    var filtered = tasks;

    if (selectedProblem != 'All') {
      filtered = filtered
          .where((t) => (t['problem_title'] ?? 'None') == selectedProblem)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) => (t['title'] ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  Future<void> _addTask() async {
    String title = '';
    int? selectedProblemId;
    String selectedProblemTitle = 'None';

    final problems = await api.getProblems();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Task Title'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: selectedProblemId,
              decoration: const InputDecoration(labelText: 'Problem'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                ...problems.map<DropdownMenuItem<int?>>(
                  (p) => DropdownMenuItem<int?>(
                    value: p['id'],
                    child: Text(p['title'] ?? 'Unknown'),
                  ),
                ),
              ],
              onChanged: (val) {
                selectedProblemId = val;
                selectedProblemTitle = val == null
                    ? 'None'
                    : problems.firstWhere((p) => p['id'] == val)['title'] ??
                          'Unknown';
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (title.isEmpty) return;

              final created = await api.createTask(
                title,
                selectedProblemId ?? 0,
              );

              created['title'] = created['title'] ?? '';
              created['done'] = created['done'] == true || created['done'] == 1;
              created['problem_title'] = selectedProblemTitle;

              setState(() => tasks.insert(0, created));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    String updatedTitle = task['title'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(
          controller: TextEditingController(text: task['title']),
          onChanged: (v) => updatedTitle = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = await api.updateTask(
                task['id'],
                title: updatedTitle,
              );

              updated['title'] = updated['title'] ?? '';
              updated['done'] = updated['done'] == true || updated['done'] == 1;
              updated['problem_title'] = task['problem_title'] ?? 'None';

              final index = tasks.indexWhere((t) => t['id'] == updated['id']);
              if (index != -1) setState(() => tasks[index] = updated);

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    await api.deleteTask(task['id']);
    setState(() {
      tasks.removeWhere((t) => t['id'] == task['id']);
    });
  }

  // ⛔️ untouched toggle logic (your original behavior)
  void _toggleComplete(Map<String, dynamic> task) {
    setState(() {
      task['done'] = !(task['done'] as bool);
    });
    api.updateTask(task['id'], done: task['done'], title: task['title']);
  }

  @override
  Widget build(BuildContext context) {
    final currentTasks = filteredTasks
        .where((t) => t['done'] == false)
        .toList();
    final completedTasks = filteredTasks
        .where((t) => t['done'] == true)
        .toList();

    final problemTitles = <String>{
      'All',
      ...tasks.map((t) => t['problem_title'] ?? 'None'),
    }.toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tasks'),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() => searchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: selectedProblem,
                        items: problemTitles
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => selectedProblem = v);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        if (currentTasks.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Current Tasks',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ...currentTasks.map(_buildTaskTile),
                        if (completedTasks.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Completed Tasks',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ...completedTasks.map(_buildTaskTile),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.sage,
        elevation: 2,
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          task['title'],
          style: TextStyle(
            decoration: task['done'] ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task['problem_title'] ?? 'None'),
        leading: Checkbox(
          value: task['done'],
          onChanged: (_) => _toggleComplete(task),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') _editTask(task);
            if (val == 'delete') _deleteTask(task);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
