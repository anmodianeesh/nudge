import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class FriendNudgesScreen extends StatefulWidget {
  const FriendNudgesScreen({super.key});

  @override
  State<FriendNudgesScreen> createState() => _FriendNudgesScreenState();
}

class _FriendNudgesScreenState extends State<FriendNudgesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFriend = 'All';

  final List<String> _friends = ['All', 'John', 'Oliver'];
  final List<Map<String, dynamic>> _friendNudges = [
    {
      'title': 'Morning Run',
      'description': 'Run 3 miles together',
      'friend': 'John',
      'status': 'pending',
      'streak': 5,
    },
    {
      'title': 'Read Daily',
      'description': 'Read for 30 minutes',
      'friend': 'Oliver',
      'status': 'active',
      'streak': 12,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNudges = _friendNudges.where((nudge) {
      final matchesSearch = nudge['title'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFriend = _selectedFriend == 'All' || nudge['friend'] == _selectedFriend;
      return matchesSearch && matchesFriend;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Friend Nudges'),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to invite friend for nudge
            },
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
                    hintText: 'Search friend nudges...',
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
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      final isSelected = _selectedFriend == friend;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(friend),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFriend = friend);
                          },
                          backgroundColor: AppTheme.backgroundGray,
                          selectedColor: Colors.green.withOpacity(0.2),
                          checkmarkColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Friend Nudges List
          Expanded(
            child: filteredNudges.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outlined,
                          size: 80,
                          color: AppTheme.textGray,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No friend nudges yet',
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
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                    child: Text(
                                      nudge['friend'][0],
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'with ${nudge['friend']}',
                                    style: const TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: nudge['status'] == 'active'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      nudge['status'],
                                      style: TextStyle(
                                        color: nudge['status'] == 'active'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                                    Icons.local_fire_department,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${nudge['streak']} day streak',
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