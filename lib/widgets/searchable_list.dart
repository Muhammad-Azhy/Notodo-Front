import 'package:flutter/material.dart';

class SearchableList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) titleSelector;

  const SearchableList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.titleSelector,
  });

  @override
  State<SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<T> get filteredItems {
    if (searchQuery.isEmpty) return widget.items;
    return widget.items
        .where(
          (item) => widget
              .titleSelector(item)
              .toLowerCase()
              .contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Search problems...",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => setState(() => searchQuery = val),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => widget.itemBuilder(items[index]),
            ),
          ),
        ),
      ],
    );
  }
}
