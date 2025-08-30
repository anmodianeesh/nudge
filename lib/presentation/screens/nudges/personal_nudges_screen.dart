import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nudge/presentation/screens/chat/chat_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../../../business_logic/cubits/nudges_cubit.dart';
import '../../../business_logic/states/nudges_state.dart';
import '../../../data/models/nudge_model.dart';
import '../../../data/repositories/nudge_repository.dart';
import 'widgets/personal_nudges_list.dart';
import '../../screens/nudges/premade_nudges_screen.dart';


class PersonalNudgesScreen extends StatefulWidget {
  const PersonalNudgesScreen({super.key});

  @override
  State<PersonalNudgesScreen> createState() => _PersonalNudgesScreenState();
}

class _PersonalNudgesScreenState extends State<PersonalNudgesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSelectionMode = false;
  final Set<String> _selectedNudgeIds = <String>{};

  final _repo = NudgeRepository();

  
  // Deleted nudges system (temporary storage with undo capability)
  final Map<String, _DeletedNudge> _deletedNudges = <String, _DeletedNudge>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNudgeIds.clear();
      }
    });
  }

  void _selectAll(List<Nudge> personalNudges) {
    setState(() {
      if (_selectedNudgeIds.length == personalNudges.length) {
        _selectedNudgeIds.clear();
      } else {
        _selectedNudgeIds.clear();
        _selectedNudgeIds.addAll(personalNudges.map((n) => n.id));
      }
    });
  }

  void _deleteSelectedNudges(BuildContext context) {
    if (_selectedNudgeIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Delete Nudges'),
            ],
          ),
          content: Text(
            _selectedNudgeIds.length == 1
                ? 'Move this nudge to deleted items? You can restore it later from your profile.'
                : 'Move ${_selectedNudgeIds.length} nudges to deleted items? You can restore them later from your profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _moveToDeleted(context, _selectedNudgeIds.toList());
                setState(() {
                  _selectedNudgeIds.clear();
                  _isSelectionMode = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _moveToDeleted(BuildContext context, List<String> nudgeIds) {
    final cubit = context.read<NudgesCubit>();
    final state = cubit.state;
    
    // Store deleted nudges with restoration info
    for (final id in nudgeIds) {
      final nudge = state.myNudges.firstWhere((n) => n.id == id);
      final schedule = state.schedules[id];
      final todayCount = state.dailyCountFor(id, DateTime.now());
      
      _deletedNudges[id] = _DeletedNudge(
        nudge: nudge,
        schedule: schedule,
        todayCount: todayCount,
        deletedAt: DateTime.now(),
      );
      
      // Remove from cubit
      cubit.removeFromMyNudges(id);
    }
    
    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nudgeIds.length == 1
              ? 'Nudge moved to deleted items'
              : '${nudgeIds.length} nudges moved to deleted items',
        ),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () => _undoDelete(context, nudgeIds),
        ),
      ),
    );
  }

  void _undoDelete(BuildContext context, List<String> nudgeIds) {
    final cubit = context.read<NudgesCubit>();
    
    for (final id in nudgeIds) {
      final deletedNudge = _deletedNudges[id];
      if (deletedNudge != null) {
        // First, add the nudge back to allNudges if it's not there
        final currentAllNudges = cubit.state.allNudges;
        final nudgeExists = currentAllNudges.any((n) => n.id == id);
        
        if (!nudgeExists) {
          // Add nudge back to allNudges
          final updatedAllNudges = List<Nudge>.from(currentAllNudges)..add(deletedNudge.nudge);
          cubit.emit(cubit.state.copyWith(allNudges: updatedAllNudges));
        }
        
        // Then add to myNudges
        cubit.addToMyNudges(id);
        
        // Restore schedule if it existed
        if (deletedNudge.schedule != null) {
          cubit.setSchedule(id, deletedNudge.schedule!);
        }
        
        // Restore today's count using log/undo operations
        final today = DateTime.now();
        final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final currentCount = cubit.state.dailyLogs[todayKey]?[id] ?? 0;
        final targetCount = deletedNudge.todayCount;
        final diff = targetCount - currentCount;
        
        if (diff > 0) {
          for (int i = 0; i < diff; i++) {
            cubit.logNow(id);
          }
        } else if (diff < 0) {
          for (int i = 0; i < -diff; i++) {
            cubit.undoLog(id);
          }
        }
        
        // Remove from deleted
        _deletedNudges.remove(id);
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nudgeIds.length == 1
              ? 'Nudge restored'
              : '${nudgeIds.length} nudges restored',
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _editNudge(BuildContext context, Nudge nudge) async {
    final cubit = context.read<NudgesCubit>();
    final state = cubit.state;
    
    await _openEditSheet(context, state, nudge);
  }

  Future<void> _openEditSheet(BuildContext context, NudgesState state, Nudge nudge) async {
    final schedule = state.schedules[nudge.id];
    final kindInitial = schedule?.kind ?? ScheduleKind.timesPerDay;
    final targetInitial = schedule?.dailyTarget ?? 1;
    final todayCount = state.dailyCountFor(nudge.id, DateTime.now());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: _EditNudgeSheet(
            nudge: nudge,
            initialKind: kindInitial,
            initialTarget: targetInitial,
            initialCount: todayCount,
            onSave: (newKind, newTarget, newCount) async {
              final cubit = context.read<NudgesCubit>();
              
              // Update schedule
              cubit.setSchedule(
                nudge.id,
                NudgeScheduleSimple(kind: newKind, dailyTarget: newTarget),
              );

              // Update today's logged count
              final currentCount = state.dailyCountFor(nudge.id, DateTime.now());
              final diff = newCount - currentCount;
              if (diff > 0) {
                for (int i = 0; i < diff; i++) {
                  cubit.logNow(nudge.id);
                }
              } else if (diff < 0) {
                for (int i = 0; i < -diff; i++) {
                  cubit.undoLog(nudge.id);
                }
              }

              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedNudgeIds.length} selected')
            : const Text(
                'Personal Nudges',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedNudgeIds.isEmpty ? null : () => _deleteSelectedNudges(context),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select multiple',
            ),
            PopupMenuButton<String>(
  icon: const Icon(Icons.add),
  tooltip: 'Add nudge',
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  offset: const Offset(0, 40),
  itemBuilder: (context) => [
    PopupMenuItem<String>(
      value: 'ai_chat',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 18,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Coach',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                'Create custom nudges with AI',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'premade',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.view_module_outlined,
              size: 18,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premade Nudges',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                'Choose from ready-made nudges',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ],
  onSelected: (value) {
 switch (value) {
   case 'ai_chat':
     Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
     break;
   case 'premade':
     Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PremadeNudgesScreen()),
                  );
     break;
 }
},
  ),
          ],
        ],
      ),
      body: BlocBuilder<NudgesCubit, NudgesState>(
        builder: (context, state) {
          final personalNudges = state.myNudges.where((nudge) {
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
                    // Selection mode controls
                    if (_isSelectionMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _selectAll(personalNudges),
                              icon: Icon(
                                _selectedNudgeIds.length == personalNudges.length
                                    ? Icons.deselect
                                    : Icons.select_all,
                                size: 20,
                              ),
                              label: Text(
                                _selectedNudgeIds.length == personalNudges.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _selectedNudgeIds.isEmpty ? null : () => _deleteSelectedNudges(context),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Search Bar
                    if (!_isSelectionMode) ...[
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
                  ],
                ),
              ),
              // Nudges List
              Expanded(
                child: personalNudges.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology_outlined,
                                size: 48,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No nudges found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                                  ? 'Try adjusting your filters'
                                  : 'Start by adding your first nudge',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: personalNudges.length,
                        itemBuilder: (context, index) {
                          final nudge = personalNudges[index];
                          final isSelected = _selectedNudgeIds.contains(nudge.id);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _isSelectionMode
                                ? _buildSelectionModeCard(nudge, isSelected)
                                : _buildSwipeableCard(context, nudge, state),
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

  Widget _buildSelectionModeCard(Nudge nudge, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedNudgeIds.remove(nudge.id);
          } else {
            _selectedNudgeIds.add(nudge.id);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.1) : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppTheme.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textGray,
                size: 24,
              ),
            ),
            Expanded(
              child: _ModernNudgeCard(nudge: nudge, state: context.read<NudgesCubit>().state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableCard(BuildContext context, Nudge nudge, NudgesState state) {
    return Dismissible(
      key: Key(nudge.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text('Delete Nudge'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Move "${nudge.title}" to deleted items?'),
                  const SizedBox(height: 8),
                  Text(
                    'You can restore it later from your profile.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _moveToDeleted(context, [nudge.id]);
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _editNudge(context, nudge),
        child: _ModernNudgeCard(nudge: nudge, state: state),
      ),
    );
  }
}

// Modern redesigned nudge card
class _ModernNudgeCard extends StatelessWidget {
  final Nudge nudge;
  final NudgesState state;

  const _ModernNudgeCard({required this.nudge, required this.state});

  @override
  Widget build(BuildContext context) {
    final schedule = state.schedules[nudge.id];
    final count = state.dailyCountFor(nudge.id, DateTime.now());
    final target = schedule?.dailyTarget ?? 1;
    final progress = (target == 0) ? 0.0 : (count / target).clamp(0.0, 1.0);
    final isCompleted = count >= target;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.3) : AppTheme.borderGray,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(nudge.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(nudge.category),
                  size: 20,
                  color: _getCategoryColor(nudge.category),
                ),
              ),
              const SizedBox(width: 12),
              
              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nudge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nudge.category,
                      style: TextStyle(
                        fontSize: 13,
                        color: _getCategoryColor(nudge.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              if (schedule?.kind != ScheduleKind.continuous)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: AppTheme.borderGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : AppTheme.primaryPurple,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check, color: Colors.green, size: 20)
                      else
                        Text(
                          '$count/$target',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            nudge.description,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textGray,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          // Bottom stats row
          Row(
            children: [
              // Schedule info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getScheduleText(schedule?.kind),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Status
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Edit hint
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppTheme.textGray.withOpacity(0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'fitness':
        return Colors.orange;
      case 'mindfulness':
        return Colors.purple;
      case 'productivity':
        return Colors.blue;
      case 'social':
        return Colors.pink;
      case 'learning':
        return Colors.indigo;
      default:
        return AppTheme.primaryPurple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.favorite_outline;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'mindfulness':
        return Icons.self_improvement_outlined;
      case 'productivity':
        return Icons.trending_up_outlined;
      case 'social':
        return Icons.people_outline;
      case 'learning':
        return Icons.school_outlined;
      default:
        return Icons.psychology_outlined;
    }
  }

  String _getScheduleText(ScheduleKind? kind) {
    switch (kind) {
      case ScheduleKind.hourly:
        return 'Hourly';
      case ScheduleKind.timesPerDay:
        return 'Daily';
      case ScheduleKind.specificTimes:
        return 'Scheduled';
      case ScheduleKind.continuous:
        return 'Ongoing';
      default:
        return 'Daily';
    }
  }
}

// Edit nudge sheet
class _EditNudgeSheet extends StatefulWidget {
  final Nudge nudge;
  final ScheduleKind initialKind;
  final int initialTarget;
  final int initialCount;
  final Future<void> Function(ScheduleKind, int, int) onSave;

  const _EditNudgeSheet({
    required this.nudge,
    required this.initialKind,
    required this.initialTarget,
    required this.initialCount,
    required this.onSave,
  });

  @override
  State<_EditNudgeSheet> createState() => _EditNudgeSheetState();
}

class _EditNudgeSheetState extends State<_EditNudgeSheet> {
  late ScheduleKind _kind;
  late int _target;
  late int _count;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _target = widget.initialTarget <= 0 ? 1 : widget.initialTarget;
    _count = widget.initialCount.clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            height: 4,
            width: 44,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Nudge',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      widget.nudge.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Today's progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Logged:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _count > 0 ? () => setState(() => _count -= 1) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGray),
                      ),
                      child: Text(
                        '$_count',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _count < 999 ? () => setState(() => _count += 1) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Schedule settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Schedule type
                Row(
                  children: [
                    const Text(
                      'Type:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<ScheduleKind>(
                        value: _kind,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.borderGray),
                          ),
                          filled: true,
                          fillColor: AppTheme.cardWhite,
                        ),
                        items: const [
                          DropdownMenuItem(value: ScheduleKind.timesPerDay, child: Text('Times per day')),
                          DropdownMenuItem(value: ScheduleKind.hourly, child: Text('Hourly')),
                          DropdownMenuItem(value: ScheduleKind.specificTimes, child: Text('Specific times')),
                          DropdownMenuItem(value: ScheduleKind.continuous, child: Text('Continuous')),
                        ],
                        onChanged: (k) {
                          if (k != null) {
                            setState(() {
                              _kind = k;
                              if (k == ScheduleKind.continuous) _target = 1;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                if (_kind != ScheduleKind.continuous) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Target:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _target > 1 ? () => setState(() => _target -= 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderGray),
                        ),
                        child: Text(
                          '$_target',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _target < 50 ? () => setState(() => _target += 1) : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _busy ? null : () async {
                    setState(() => _busy = true);
                    await widget.onSave(_kind, _target, _count);
                    if (mounted) setState(() => _busy = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper class for deleted nudges
class _DeletedNudge {
  final Nudge nudge;
  final NudgeScheduleSimple? schedule;
  final int todayCount;
  final DateTime deletedAt;

  _DeletedNudge({
    required this.nudge,
    required this.schedule,
    required this.todayCount,
    required this.deletedAt,
  });
}