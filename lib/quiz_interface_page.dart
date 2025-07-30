import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'quiz_results_page.dart';

class QuizInterfacePage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const QuizInterfacePage({
    super.key,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<QuizInterfacePage> createState() => _QuizInterfacePageState();
}

class _QuizInterfacePageState extends State<QuizInterfacePage> with WidgetsBindingObserver {
  Timer? _timer;
  int _timeRemaining = 900; // 15 minutes in seconds
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _shuffledQuestions = [];
  Map<int, String> _userAnswers = {};
  int _score = 0;
  bool _isLoading = true;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _selectedAnswer = '';
  
  // Participant tracking
  List<Map<String, dynamic>> _participants = [];
  StreamSubscription? _participantSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadQuestions();
    _startTimer();
    _listenToParticipants();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _participantSubscription?.cancel();
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

  void _eliminateUser() async {
    if (mounted) {
      // Submit current score before elimination
      await _submitFinalScore();
      
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

  void _loadQuestions() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
        
        // Shuffle questions for this user
        final shuffled = List<Map<String, dynamic>>.from(questions);
        shuffled.shuffle(Random());
        
        setState(() {
          _questions = questions;
          _shuffledQuestions = shuffled;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  void _listenToParticipants() {
    _participantSubscription = FirebaseFirestore.instance
        .collection('quiz_scores')
        .where('quizId', isEqualTo: widget.quizId)
        .snapshots()
        .listen((snapshot) {
      final participants = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        participants.add({
          'userId': data['userId'],
          'email': data['userEmail'] ?? 'Unknown',
          'score': data['score'] ?? 0,
          'completed': data['completed'] ?? false,
          'timestamp': data['timestamp'],
        });
      }
      
      // Sort by score descending
      participants.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      if (mounted) {
        setState(() {
          _participants = participants;
        });
      }
    });
  }

  void _selectAnswer(String answer) async {
    if (_showFeedback) return; // Prevent multiple selections
    
    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correct_answer'];
    final isCorrect = answer == correctAnswer;
    

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = isCorrect;
      _showFeedback = true;
    });
    
    // Store answer
    _userAnswers[_currentQuestionIndex] = answer;
    
    // Update score
    if (isCorrect) {
      _score++;
      // Update real-time score in Firestore
      await _updateRealtimeScore();
    }
    
    // Auto-progress after 2 seconds
    Timer(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showFeedback = false;
        _selectedAnswer = '';
      });
    } else {
      _submitQuiz();
    }
  }

  Future<void> _updateRealtimeScore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('quiz_scores')
          .doc('${widget.quizId}_${user.uid}')
          .set({
        'quizId': widget.quizId,
        'userId': user.uid,
        'userEmail': user.email,
        'score': _score,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating real-time score: $e');
    }
  }

  Future<void> _submitFinalScore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('quiz_scores')
          .doc('${widget.quizId}_${user.uid}')
          .set({
        'quizId': widget.quizId,
        'userId': user.uid,
        'userEmail': user.email,
        'score': _score,
        'totalQuestions': _shuffledQuestions.length,
        'answers': _userAnswers,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error submitting final score: $e');
    }
  }

  void _submitQuiz() async {
    _timer?.cancel();
    
    // Submit final score
    await _submitFinalScore();
    
    // Navigate to results
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => QuizResultsPage(
            quizId: widget.quizId,
            quizData: widget.quizData,
            score: _score,
            totalQuestions: _shuffledQuestions.length,
            userAnswers: _userAnswers,
            questions: _shuffledQuestions,
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_timeRemaining > 300) return Colors.green; // > 5 minutes
    if (_timeRemaining > 120) return Colors.orange; // > 2 minutes
    return Colors.red; // < 2 minutes
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Loading Quiz...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF203E52),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_shuffledQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quiz Error',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF203E52),
        ),
        body: const Center(
          child: Text(
            'No questions available for this quiz.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during quiz
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.quizData['subject']} Quiz',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF203E52),
          automaticallyImplyLeading: false,
          actions: [
            // Timer
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTimerColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Live Participants Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Leaderboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final participant = _participants[index];
                        final isCurrentUser = participant['userId'] == FirebaseAuth.instance.currentUser?.uid;
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.orange[50] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrentUser ? Colors.orange : Colors.grey[300]!,
                              width: isCurrentUser ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: index == 0 ? const Color(0xFFFFD700) :
                                             index == 1 ? Colors.grey[400] :
                                             index == 2 ? Colors.brown[300] :
                                             Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCurrentUser ? 'You' : participant['email'].split('@')[0],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser ? Colors.orange[800] : const Color(0xFF203E52),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Text(
                                '${participant['score']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Quiz Content
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF5F7FA),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Progress Indicator
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Question ${_currentQuestionIndex + 1} of ${_shuffledQuestions.length}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF203E52),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Score: $_score',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (_currentQuestionIndex + 1) / _shuffledQuestions.length,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ],
                        ),
                      ),
                        
                        const SizedBox(height: 24),
                        
                        // Question Card
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
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
                                // Question Text
                                Text(
                                  currentQuestion['question'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF203E52),
                                    height: 1.4,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Answer Options
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: 4,
                                    itemBuilder: (context, index) {
                                      final options = ['A', 'B', 'C', 'D'];
                                      final option = options[index];
                                      // Get answer text from options array
                                      final questionOptions = currentQuestion['options'] as List<dynamic>? ?? [];
                                      final answerText = index < questionOptions.length ? questionOptions[index] as String : '';
                                      
                                      // Remove the letter prefix (A., B., C., D.) if present
                                      final cleanAnswerText = answerText.replaceFirst(RegExp(r'^[A-D]\. '), '');
                                      
                                      Color cardColor = Colors.grey[50]!;
                                      Color borderColor = Colors.grey[300]!;
                                      Color textColor = Colors.black; // Always black for answer text
                                      
                                      // Random colors for option letters
                                      final optionColors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
                                      Color optionLetterColor = optionColors[index % optionColors.length];
                                      
                                      if (_showFeedback && _selectedAnswer == option) {
                                        if (_isCorrect) {
                                          cardColor = Colors.green[50]!;
                                          borderColor = Colors.green;
                                          optionLetterColor = Colors.green;
                                        } else {
                                          cardColor = Colors.red[50]!;
                                          borderColor = Colors.red;
                                          optionLetterColor = Colors.red;
                                        }
                                      } else if (_showFeedback && option == currentQuestion['correct_answer']) {
                                        cardColor = Colors.green[50]!;
                                        borderColor = Colors.green;
                                        optionLetterColor = Colors.green;
                                      }
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: GestureDetector(
                                          onTap: () => _selectAnswer(option),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: borderColor, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: borderColor.withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: optionLetterColor,
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      option,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    cleanAnswerText,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                if (_showFeedback && _selectedAnswer == option)
                                                  Icon(
                                                    _isCorrect ? Icons.check_circle : Icons.cancel,
                                                    color: _isCorrect ? Colors.green : Colors.red,
                                                    size: 24,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // Feedback Message
                                if (_showFeedback)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _isCorrect ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isCorrect ? Colors.green : Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isCorrect ? Icons.check_circle : Icons.cancel,
                                          color: _isCorrect ? Colors.green : Colors.red,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _isCorrect ? 'Correct!' : 'Wrong!',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: _isCorrect ? Colors.green[800] : Colors.red[800],
                                                ),
                                              ),
                                              if (currentQuestion['explanation'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    currentQuestion['explanation'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
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
            ],
          ),
        ),
      );
    }
  }


// Extension for gold color
extension ColorExtension on Colors {
  static const Color gold = Color(0xFFFFD700);
}