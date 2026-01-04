import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ReferenceTypePicker extends StatelessWidget {
  final void Function(String type) onSelect;

  const ReferenceTypePicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [_icon(context, Icons.description, "text")],
        ),
      ),
    );
  }

  Widget _icon(BuildContext context, IconData icon, String type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelect(type);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.sage),
          const SizedBox(height: 6),
          Text(type.toUpperCase(), style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
