import 'package:flutter/material.dart';
import 'package:front/Services/api_services.dart';
import '../../theme/app_colors.dart';

class TasksSection extends StatefulWidget {
  final int problemId;

  const TasksSection({super.key, required this.problemId});

  @override
  State<TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<TasksSection> {
  final ApiService api = ApiService();
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final tasks = await api.getTasks(problemId: widget.problemId);
      setState(() => _tasks = tasks);
    } catch (e) {
      print("Failed to load tasks: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load tasks")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleComplete(Map<String, dynamic> task) async {
    try {
      final updated = await api.updateTask(
        task['id'],
        title: task['title'],
        done: !(task['done'] as bool? ?? false),
      );
      setState(() {
        task['done'] = updated['done'];
      });
    } catch (e) {
      print("Failed to update task: $e");
    }
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    String newTitle = task['title'];
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Task"),
        content: TextField(
          controller: TextEditingController(text: task['title']),
          onChanged: (val) => newTitle = val,
          decoration: const InputDecoration(labelText: "Task Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newTitle.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                final updated = await api.updateTask(
                  task['id'],
                  title: newTitle.trim(),
                  done: task['done'] as bool? ?? false,
                );
                setState(() {
                  task['title'] = updated['title'];
                });
              } catch (e) {
                print("Failed to update task: $e");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    try {
      await api.deleteTask(task['id']);
      setState(() {
        _tasks.remove(task);
      });
    } catch (e) {
      print("Failed to delete task: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete task")));
    }
  }

  Future<void> _addTask() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Task"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Task Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;
              Navigator.pop(context); // close dialog first

              try {
                final newTask = await api.createTask(
                  newTitle,
                  widget.problemId,
                );
                setState(() => _tasks.add(newTask));
              } catch (e) {
                print("Failed to create task: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to add task")),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ..._tasks.map(
          (task) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Checkbox(
                value: task['done'] as bool? ?? false,
                onChanged: (_) => _toggleComplete(task),
                activeColor: AppColors.sage,
              ),
              title: Text(
                task['title'] ?? 'Untitled Task',
                style: TextStyle(
                  decoration: task['done'] == true
                      ? TextDecoration.lineThrough
                      : null,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editTask(task);
                  if (value == 'delete') _deleteTask(task);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text("Edit")),
                  PopupMenuItem(value: 'delete', child: Text("Delete")),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Task"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _addTask,
          ),
        ),
      ],
    );
  }
}
