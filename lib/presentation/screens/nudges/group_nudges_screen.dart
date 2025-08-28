import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class GroupNudgesScreen extends StatefulWidget {
  const GroupNudgesScreen({super.key});

  @override
  State<GroupNudgesScreen> createState() => _GroupNudgesScreenState();
}

class _GroupNudgesScreenState extends State<GroupNudgesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGroup = 'All';

  // Mock data for now
  final List<String> _groups = ['All', 'School', 'Work', 'Family'];
  final List<Map<String, dynamic>> _groupNudges = [
    {
      'title': 'Submit Assignment',
      'description': 'Complete and submit weekly assignment',
      'group': 'School',
      'participants': 15,
      'dueDate': 'Today',
    },
    {
      'title': 'Team Stand-up',
      'description': 'Attend daily team meeting',
      'group': 'Work',
      'participants': 8,
      'dueDate': '9:00 AM',
    },
  ];
void _showGroupNudgeOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Group Nudge Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: AppTheme.primaryPurple,
              ),
            ),
            title: const Text('Create with AI'),
            subtitle: const Text('AI-powered group challenges'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to AI chat for group nudges
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: Colors.green,
              ),
            ),
            title: const Text('Create Group Challenge'),
            subtitle: const Text('Start a new group nudge'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to create group nudge screen
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.group_add_outlined,
                color: Colors.orange,
              ),
            ),
            title: const Text('Join Existing'),
            subtitle: const Text('Join a group challenge'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to join group screen
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final filteredNudges = _groupNudges.where((nudge) {
      final matchesSearch = nudge['title'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGroup = _selectedGroup == 'All' || nudge['group'] == _selectedGroup;
      return matchesSearch && matchesGroup;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Group Nudges'),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showGroupNudgeOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search group nudges...',
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
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      final isSelected = _selectedGroup == group;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedGroup = group);
                          },
                          backgroundColor: AppTheme.backgroundGray,
                          selectedColor: Colors.blue.withOpacity(0.2),
                          checkmarkColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Group Nudges List
          Expanded(
            child: filteredNudges.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 80,
                          color: AppTheme.textGray,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No group nudges yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNudges.length,
                    itemBuilder: (context, index) {
                      final nudge = filteredNudges[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.cardWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      nudge['group'],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    nudge['dueDate'],
                                    style: const TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                nudge['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nudge['description'],
                                style: const TextStyle(
                                  color: AppTheme.textGray,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 16,
                                    color: AppTheme.textGray,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${nudge['participants']} participants',
                                    style: const TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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