import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ReferenceCard extends StatelessWidget {
  final Map<String, dynamic> ref;
  final VoidCallback? onDelete;

  const ReferenceCard({super.key, required this.ref, this.onDelete});

  String _getTextContent(String? content) {
    if (content == null) return '';
    try {
      final parsed = jsonDecode(content);
      if (parsed is List) {
        return parsed.map((op) => op['insert'] ?? '').join();
      }
    } catch (_) {}
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = Theme.of(context).textTheme.bodyMedium!.color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref['title'] ?? 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ref['type'] == 'image'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            ref['content'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : File(
                            ref['content'] != null
                                ? File(ref['content']!).path
                                : '',
                          ).existsSync()
                        ? Image.file(
                            File(ref['content']!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(color: Theme.of(context).dividerColor),
                  )
                : Text(
                    _getTextContent(ref['content']),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: contentColor?.withOpacity(0.9),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          if (onDelete != null)
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}
