import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_interface_page.dart';

class QuizRulesPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const QuizRulesPage({
    super.key,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<QuizRulesPage> createState() => _QuizRulesPageState();
}

class _QuizRulesPageState extends State<QuizRulesPage> with WidgetsBindingObserver {
  bool _isReady = false;
  bool _hasAcceptedRules = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // User backgrounded the app - eliminate them
      _eliminateUser();
    }
  }

  void _eliminateUser() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have been eliminated for backgrounding the app!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _startQuiz() {
    if (!_hasAcceptedRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the rules before starting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuizInterfacePage(
          quizId: widget.quizId,
          quizData: widget.quizData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during rules
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quiz Rules & Instructions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF203E52),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF203E52),
                Color(0xFF2A4A5E),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Quiz Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${widget.quizData['subject']} Quiz',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF203E52),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level: ${widget.quizData['level']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quiz Code: ${widget.quizData['quizCode']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF203E52),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rules Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.rule,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Quiz Rules & Instructions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF203E52),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRuleItem(
                                    Icons.timer,
                                    'Time Limit',
                                    'You have exactly 15 minutes to complete all 20 questions.',
                                    Colors.orange,
                                  ),
                                  _buildRuleItem(
                                    Icons.phone_android,
                                    'No Backgrounding',
                                    'If you minimize or background the app, you will be automatically eliminated.',
                                    Colors.red,
                                  ),
                                  _buildRuleItem(
                                    Icons.shuffle,
                                    'Random Questions',
                                    'Questions will be presented in random order for each participant.',
                                    Colors.blue,
                                  ),
                                  _buildRuleItem(
                                    Icons.touch_app,
                                    'Answer Selection',
                                    'Tap on your chosen answer. You will see immediate feedback (Correct/Wrong).',
                                    Colors.green,
                                  ),
                                  _buildRuleItem(
                                    Icons.skip_next,
                                    'Auto Progression',
                                    'After selecting an answer, you will automatically move to the next question.',
                                    Colors.purple,
                                  ),
                                  _buildRuleItem(
                                    Icons.leaderboard,
                                    'Live Scoring',
                                    'See real-time scores of other participants during the quiz.',
                                    Colors.indigo,
                                  ),
                                  _buildRuleItem(
                                    Icons.auto_awesome,
                                    'Final Results',
                                    'Your final score will be displayed at the end and recorded permanently.',
                                    Colors.amber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Accept Rules Checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasAcceptedRules,
                          onChanged: (value) {
                            setState(() {
                              _hasAcceptedRules = value ?? false;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and accept all the quiz rules and instructions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF203E52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Start Quiz Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _hasAcceptedRules ? _startQuiz : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasAcceptedRules ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _hasAcceptedRules ? 8 : 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'START QUIZ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF203E52),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}