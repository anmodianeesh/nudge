import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/nudge_model.dart';
import 'package:nudge/data/premade_nudges_data.dart';

class PremadeNudgesScreen extends StatefulWidget {
  const PremadeNudgesScreen({super.key});

  @override
  State<PremadeNudgesScreen> createState() => _PremadeNudgesScreenState();
}

class _PremadeNudgesScreenState extends State<PremadeNudgesScreen> {
  late final List<Nudge> _allNudges;
  late final List<String> _categories; // ["All", ...unique categories]

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  bool _activeOnly = false;

  @override
  void initState() {
    super.initState();
    _allNudges = List<Nudge>.from(PremadeNudgesData.allNudges);
    // Build category list from data
    final unique = _allNudges.map((e) => e.category).toSet().toList()..sort();
    _categories = ['All', ...unique];

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Nudge> get _filtered {
    final q = _query.toLowerCase();

    return _allNudges.where((n) {
      final matchesQuery = q.isEmpty
          ? true
          : (n.title.toLowerCase().contains(q) ||
              n.description.toLowerCase().contains(q) ||
              n.category.toLowerCase().contains(q));

      final matchesCategory =
          _selectedCategory == 'All' ? true : n.category == _selectedCategory;

      final matchesActive = _activeOnly ? n.isActive : true;

      return matchesQuery && matchesCategory && matchesActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nudges = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: const Text('Browse Nudges'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchField(
              controller: _searchCtrl,
              hintText: 'Search nudges…',
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Filters Row
          Container(
            width: double.infinity,
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories as chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: AppTheme.backgroundGray,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Active only toggle
                Row(
                  children: [
                    Switch(
                      value: _activeOnly,
                      activeColor: AppTheme.primaryPurple,
                      onChanged: (v) => setState(() => _activeOnly = v),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Active only',
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: nudges.isEmpty
                ? _EmptyState(
                    query: _query,
                    selectedCategory: _selectedCategory,
                    activeOnly: _activeOnly,
                    onClearSearch: () {
                      _searchCtrl.clear();
                      setState(() {
                        _selectedCategory = 'All';
                        _activeOnly = false;
                      });
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: nudges.length,
                    itemBuilder: (context, index) {
                      final Nudge nudge = nudges[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb_outline,
                                      color: AppTheme.primaryPurple,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nudge.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          nudge.category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textGray,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${nudge.title} added to My Nudges'),
                                          backgroundColor:
                                              AppTheme.primaryPurple,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                nudge.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textGray,
                                  height: 1.4,
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
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const _SearchField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: AppTheme.textGray),
              hintText: hintText,
              hintStyle: const TextStyle(color: AppTheme.textGray),
              border: InputBorder.none,
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textGray),
                      onPressed: () => controller.clear(),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  final String query;
  final String selectedCategory;
  final bool activeOnly;
  final VoidCallback onClearSearch;

  const _EmptyState({
    required this.query,
    required this.selectedCategory,
    required this.activeOnly,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.textGray),
            const SizedBox(height: 12),
            const Text(
              "No nudges found",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _buildReason(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearSearch,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildReason() {
    final parts = <String>[];
    if (query.isNotEmpty) parts.add('“$query”');
    if (selectedCategory != 'All') parts.add('category: $selectedCategory');
    if (activeOnly) parts.add('active only');
    if (parts.isEmpty) return 'Try a different query or category.';
    return 'No results for ${parts.join(' • ')}.';
  }
}
