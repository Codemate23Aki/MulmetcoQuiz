import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizResultsPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;
  final int score;
  final int totalQuestions;
  final Map<int, String> userAnswers;
  final List<Map<String, dynamic>> questions;

  const QuizResultsPage({
    super.key,
    required this.quizId,
    required this.quizData,
    required this.score,
    required this.totalQuestions,
    required this.userAnswers,
    required this.questions,
  });

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save quiz result to history collection
      await FirebaseFirestore.instance
          .collection('quiz_history')
          .doc('${widget.quizId}_${user.uid}')
          .set({
        'quizId': widget.quizId,
        'userId': user.uid,
        'userEmail': user.email,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'percentage': (widget.score / widget.totalQuestions) * 100,
        'grade': _getGrade(),
        'subject': widget.quizData['subject'] ?? 'Unknown',
        'level': widget.quizData['level'] ?? 'Unknown',
        'userAnswers': widget.userAnswers,
        'questions': widget.questions,
        'completedAt': FieldValue.serverTimestamp(),
        'quizData': widget.quizData,
      });

      // Update quiz status to completed for this user
      await FirebaseFirestore.instance
          .collection('quiz_scores')
          .doc('${widget.quizId}_${user.uid}')
          .update({
        'completed': true,
        'movedToHistory': true,
      });

      print('Quiz result saved to history successfully');
    } catch (e) {
      print('Error saving quiz to history: $e');
    }
  }

  void _loadLeaderboard() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quiz_scores')
          .where('quizId', isEqualTo: widget.quizId)
          .where('completed', isEqualTo: true)
          .orderBy('score', descending: true)
          .orderBy('completedAt')
          .get();
      
      final leaderboard = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        leaderboard.add({
          'userId': data['userId'],
          'email': data['userEmail'] ?? 'Unknown',
          'score': data['score'] ?? 0,
          'totalQuestions': data['totalQuestions'] ?? widget.totalQuestions,
          'completedAt': data['completedAt'],
        });
      }
      
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getUserRank() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i]['userId'] == currentUserId) {
        return i + 1;
      }
    }
    return -1;
  }

  double _getPercentage() {
    return (widget.score / widget.totalQuestions) * 100;
  }

  String _getGrade() {
    final percentage = _getPercentage();
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    return 'F';
  }

  Color _getGradeColor() {
    final percentage = _getPercentage();
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _getPercentage();
    final grade = _getGrade();
    final rank = _getUserRank();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF203E52),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: const Icon(
              Icons.home,
              color: Colors.white,
            ),
            tooltip: 'Home',
          ),
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Results Header
                Container(
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
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: _getGradeColor(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Quiz Completed!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF203E52),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.quizData['subject']} - ${widget.quizData['level']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Score Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildScoreItem(
                            'Score',
                            '${widget.score}/${widget.totalQuestions}',
                            Colors.blue,
                          ),
                          _buildScoreItem(
                            'Percentage',
                            '${percentage.toStringAsFixed(1)}%',
                            Colors.orange,
                          ),
                          _buildScoreItem(
                            'Grade',
                            grade,
                            _getGradeColor(),
                          ),
                          if (rank > 0)
                            _buildScoreItem(
                              'Rank',
                              '#$rank',
                              Colors.purple,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Leaderboard
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.leaderboard,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Final Leaderboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF203E52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_leaderboard.isEmpty)
                        const Center(
                          child: Text(
                            'No results available yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            final participant = _leaderboard[index];
                            final isCurrentUser = participant['userId'] == FirebaseAuth.instance.currentUser?.uid;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.orange[50] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrentUser ? Colors.orange : Colors.grey[300]!,
                                  width: isCurrentUser ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: index == 0 ? const Color(0xFFFFD700) : // Gold
                                             index == 1 ? Colors.grey[400] :
                                             index == 2 ? Colors.brown[300] :
                                             Colors.grey[300],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCurrentUser ? 'You' : participant['email'].split('@')[0],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isCurrentUser ? Colors.orange[800] : const Color(0xFF203E52),
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${((participant['score'] / participant['totalQuestions']) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${participant['score']}/${participant['totalQuestions']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrentUser ? Colors.orange[800] : const Color(0xFF203E52),
                                        ),
                                      ),
                                      if (index < 3)
                                        Icon(
                                          index == 0 ? Icons.emoji_events :
                                          index == 1 ? Icons.military_tech :
                                          Icons.workspace_premium,
                                          color: index == 0 ? const Color(0xFFFFD700) :
                                                 index == 1 ? Colors.grey[400] :
                                                 Colors.brown[300],
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Question Review
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Question Review',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF203E52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.questions.length,
                        itemBuilder: (context, index) {
                          final question = widget.questions[index];
                          final userAnswer = widget.userAnswers[index];
                          final correctAnswer = question['correct_answer'];
                          final isCorrect = userAnswer == correctAnswer;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCorrect ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCorrect ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Q${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.cancel,
                                      color: isCorrect ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                    const Spacer(),
                                    Text(
                                      isCorrect ? 'Correct' : 'Wrong',
                                      style: TextStyle(
                                        color: isCorrect ? Colors.green[800] : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  question['question'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF203E52),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (userAnswer != null)
                                  Text(
                                    'Your answer: $userAnswer. ${question['option$userAnswer'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCorrect ? Colors.green[700] : Colors.red[700],
                                    ),
                                  ),
                                if (!isCorrect)
                                  Text(
                                    'Correct answer: $correctAnswer. ${question['option$correctAnswer'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (question['explanation'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Explanation: ${question['explanation']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF203E52),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}