import 'package:flutter/material.dart';
import 'package:front/Services/api_services.dart';
import 'package:front/screens/update_references_page.dart';
import 'reference_card.dart';
import 'reference_type_picker.dart';

class ReferencesSection extends StatefulWidget {
  final List<Map<String, dynamic>> references;
  final void Function(String type) onAdd;
  final void Function(Map<String, dynamic>)? onTap;

  const ReferencesSection({
    super.key,
    required this.references,
    required this.onAdd,
    required this.onTap,
  });

  @override
  State<ReferencesSection> createState() => _ReferencesSectionState();
}

class _ReferencesSectionState extends State<ReferencesSection> {
  String query = "";
  final ApiService api = ApiService();

  void _openReference(BuildContext context, Map<String, dynamic> ref) async {
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
      final index = widget.references.indexWhere(
        (r) => r['id'] == updatedRef['id'],
      );
      if (index != -1) {
        setState(() {
          widget.references[index] = updatedRef;
        });
      }
    }
  }

  void _deleteReference(BuildContext context, Map<String, dynamic> ref) {
    final refId = ref['id'];
    if (refId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Delete Reference",
          style: Theme.of(ctx).textTheme.titleMedium,
        ),
        content: Text(
          "Are you sure you want to delete this reference?",
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: Theme.of(ctx).textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(ctx);
                await api.deleteReference(refId);
                setState(() {
                  widget.references.removeWhere((r) => r['id'] == refId);
                });
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
              }
            },
            child: Text(
              "Delete",
              style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ReferenceTypePicker(onSelect: widget.onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final filtered = widget.references.where((r) {
      return (r['title'] ?? "").toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              "References",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            hintText: "Search references...",
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
            filled: true,
            fillColor: theme.cardColor, // uses cardTheme color automatically
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, i) {
            // Add new reference button
            if (i == filtered.length) {
              return InkWell(
                onTap: () => _openPicker(context),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: cs.surface, // theme surface (light/dark)
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 48,
                      color: cs.primary, // brand color instead of grey
                    ),
                  ),
                ),
              );
            }

            final ref = filtered[i];
            return GestureDetector(
              onTap: () {
                if (widget.onTap != null) widget.onTap!(ref);
              },
              child: ReferenceCard(
                ref: ref,
                onDelete: () => _deleteReference(context, ref),
              ),
            );
          },
        ),
      ],
    );
  }
}
