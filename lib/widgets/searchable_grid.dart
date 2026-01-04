import 'package:flutter/material.dart';

class SearchableGrid<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) titleSelector;

  const SearchableGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.titleSelector,
  });

  @override
  State<SearchableGrid<T>> createState() => _SearchableGridState<T>();
}

class _SearchableGridState<T> extends State<SearchableGrid<T>>
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
        TextField(
          decoration: const InputDecoration(
            hintText: "Search...",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (val) => setState(() => searchQuery = val),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return widget.itemBuilder(items[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
