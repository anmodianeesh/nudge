import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../home/home_screen.dart';  // Fixed path

class UserInfoScreen extends StatefulWidget {
  final String userName;
  
  const UserInfoScreen({
    super.key,
    required this.userName,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  
  // Form controllers
  final TextEditingController _goalController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _primaryGoal;
  List<String> _selectedChallenges = [];
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _goalOptions = [
    'Build better habits',
    'Improve health & fitness',
    'Boost productivity',
    'Reduce stress',
    'Sleep better',
    'Learn something new'
  ];
  final List<String> _challengeOptions = [
    'Staying consistent',
    'Forgetting to do habits',
    'Lack of motivation',
    'Too busy',
    'Don\'t know where to start',
    'Breaking bad habits'
  ];

  @override
  void dispose() {
    _goalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _pageController.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _pageController.previousPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // Save user data (will implement with backend later)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            _buildProgressHeader(),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(),
                  _buildGoalStep(),
                  _buildPersonalInfoStep(),
                  _buildChallengesStep(),
                ],
              ),
            ),
            
            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back_ios),
                  color: AppTheme.textDark,
                )
              else
                const SizedBox(width: 40),
              Text(
                'Step ${currentStep + 1} of 4',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (currentStep + 1) / 4,
            backgroundColor: AppTheme.borderGray,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 50,
              color: AppTheme.cardWhite,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Hi ${widget.userName}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Nudge! I\'m your AI behavioral companion. Let me ask you a few quick questions so I can personalize your experience.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your data is private and secure. You can update these preferences anytime.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'What brings you to Nudge?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps me understand what matters most to you',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _goalOptions.length,
              itemBuilder: (context, index) {
                final goal = _goalOptions[index];
                final isSelected = _primaryGoal == goal;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _primaryGoal = goal;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryPurple.withOpacity(0.1) 
                            : AppTheme.cardWhite,
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryPurple 
                              : AppTheme.borderGray,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryPurple 
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryPurple 
                                    : AppTheme.borderGray,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: AppTheme.cardWhite,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            goal,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isSelected 
                                  ? AppTheme.primaryPurple 
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPersonalInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Tell me a bit about yourself',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps me personalize nudges for your age group and preferences',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 32),
          
          // Date of Birth
          const Text(
            'Date of Birth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                border: Border.all(color: AppTheme.borderGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.textGray),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select your birth date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null 
                          ? AppTheme.textDark 
                          : AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Gender
          const Text(
            'Gender (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _genderOptions.map((gender) {
              final isSelected = _selectedGender == gender;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryPurple.withOpacity(0.1) 
                        : AppTheme.cardWhite,
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryPurple 
                          : AppTheme.borderGray,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gender,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? AppTheme.primaryPurple 
                          : AppTheme.textDark,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'What challenges do you face?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply - this helps me give you better nudges',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _challengeOptions.length,
              itemBuilder: (context, index) {
                final challenge = _challengeOptions[index];
                final isSelected = _selectedChallenges.contains(challenge);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedChallenges.remove(challenge);
                        } else {
                          _selectedChallenges.add(challenge);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryPurple.withOpacity(0.1) 
                            : AppTheme.cardWhite,
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryPurple 
                              : AppTheme.borderGray,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryPurple 
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryPurple 
                                    : AppTheme.borderGray,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: AppTheme.cardWhite,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            challenge,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isSelected 
                                  ? AppTheme.primaryPurple 
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildNavigationButtons() {
    final canProceed = _canProceedFromCurrentStep();
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: _previousStep,
                backgroundColor: AppTheme.cardWhite,
                textColor: AppTheme.textDark,
                borderColor: AppTheme.borderGray,
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: currentStep == 3 ? 'Get Started' : 'Continue',
              onPressed: canProceed ? _nextStep : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromCurrentStep() {
    switch (currentStep) {
      case 0:
        return true; // Welcome step
      case 1:
        return _primaryGoal != null; // Goal selection required
      case 2:
        return _selectedDate != null; // DOB required, gender optional
      case 3:
        return true; // Challenges optional
      default:
        return false;
    }
  }
}