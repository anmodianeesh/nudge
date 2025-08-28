import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';
import '../../widgets/nudges/nudge_card.dart';

class PersonalNudgesScreen extends StatefulWidget {
  const PersonalNudgesScreen({super.key});

  @override
  State<PersonalNudgesScreen> createState() => _PersonalNudgesScreenState();
}

class _PersonalNudgesScreenState extends State<PersonalNudgesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('My Nudges'),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add nudge screen
            },
          ),
        ],
      ),
      body: BlocBuilder<NudgesCubit, NudgesState>(
        builder: (context, state) {
          final personalNudges = state.myNudges.where((nudge) {
            // Filter for personal nudges only (not group/friend nudges)
            final matchesSearch = nudge.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                nudge.description.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCategory = _selectedCategory == 'All' || nudge.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          final categories = ['All', ...state.myNudges.map((n) => n.category).toSet().toList()]..sort();

          return Column(
            children: [
              // Search and Filter
              Container(
                color: AppTheme.cardWhite,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search nudges...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderGray),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category Filter
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = category);
                              },
                              backgroundColor: AppTheme.backgroundGray,
                              selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryPurple,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Nudges List
              Expanded(
                child: personalNudges.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 80,
                              color: AppTheme.textGray,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No personal nudges yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGray,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start by adding your first nudge',
                              style: TextStyle(
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: personalNudges.length,
                        itemBuilder: (context, index) {
                          final nudge = personalNudges[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NudgeCard(nudge: nudge),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}