import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'quiz_rules_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStartQuizDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StartQuizBottomSheet(),
    );
  }

  void _showMyRaces(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MyRacesBottomSheet(),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HistoryBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mulmetco Quiz',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF203E52),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Sign Out',
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Welcome Section
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          backgroundColor: Colors.orange,
                          child: user?.photoURL == null
                              ? Text(
                                  user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome, ${user?.displayName ?? 'User'}!',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF203E52),
                          ),
                          textAlign: TextAlign.center,
                        ),
                   
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ready to challenge your knowledge?',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF203E52),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Quick Actions
                  SizedBox(
                    height: 400, // Fixed height for the grid
                    child: GridView.count(
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildQuickActionCard(
                          icon: Icons.quiz,
                          title: 'Start Quiz',
                          subtitle: 'Begin a new challenge',
                          color: Colors.orange,
                          onTap: () => _showStartQuizDialog(context),
                        ),
                        _buildQuickActionCard(
                          icon: Icons.emoji_events,
                          title: 'My Races',
                          subtitle: 'Your quiz history',
                          color: const Color(0xFF203E52),
                          onTap: () => _showMyRaces(context),
                        ),
                        _buildQuickActionCard(
                          icon: Icons.history,
                          title: 'History',
                          subtitle: 'Past quizzes',
                          color: Colors.green,
                          onTap: () => _showHistory(context),
                        ),
                        _buildQuickActionCard(
                          icon: Icons.settings,
                          title: 'Settings',
                          subtitle: 'Preferences',
                          color: Colors.grey,
                          onTap: () {
                            // TODO: Navigate to settings
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings feature coming soon!'),
                                backgroundColor: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ],
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
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203E52),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartQuizBottomSheet extends StatefulWidget {
  const StartQuizBottomSheet({super.key});

  @override
  State<StartQuizBottomSheet> createState() => _StartQuizBottomSheetState();
}

class _StartQuizBottomSheetState extends State<StartQuizBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Start Quiz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203E52),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.add_circle,
                    title: 'Create Quiz',
                    subtitle: 'Start a new quiz',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showCreateQuizDialog(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.login,
                    title: 'Join Quiz',
                    subtitle: 'Enter quiz code',
                    color: const Color(0xFF203E52),
                    onTap: () {
                      Navigator.pop(context);
                      _showJoinQuizDialog(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateQuizDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateQuizDialog(),
    );
  }

  void _showJoinQuizDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinQuizDialog(),
    );
  }
}

class MyRacesBottomSheet extends StatelessWidget {
  const MyRacesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Races',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203E52),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('quizzes')
                    .where('participants', arrayContains: user?.uid)
                    .where('status', isEqualTo: 'ready') // Only show active/ready quizzes
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quizzes yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start or join a quiz to see it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Filter out completed quizzes using StreamBuilder for quiz_scores
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('quiz_scores')
                        .where('userId', isEqualTo: user?.uid)
                        .where('completed', isEqualTo: true)
                        .snapshots(),
                    builder: (context, scoresSnapshot) {
                      if (scoresSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // Get list of completed quiz IDs for current user
                      final completedQuizIds = <String>{};
                      if (scoresSnapshot.hasData) {
                        for (final doc in scoresSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          completedQuizIds.add(data['quizId'] as String);
                        }
                      }
                      
                      // Filter out completed quizzes from the quiz list
                      final activeQuizzes = snapshot.data!.docs.where((doc) {
                        return !completedQuizIds.contains(doc.id);
                      }).toList();
                      
                      if (activeQuizzes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No active quizzes',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start or join a new quiz to see it here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                  
                  return ListView.builder(
                     itemCount: activeQuizzes.length,
                     itemBuilder: (context, index) {
                       final quiz = activeQuizzes[index];
                       final quizData = quiz.data() as Map<String, dynamic>;
                      
                      return GestureDetector(
                        onTap: () {
                          print('Quiz tile tapped! Quiz ID: ${quiz.id}');
                          print('Quiz status: ${quizData['status']}');
                          print('Quiz data: $quizData');
                          
                          // Navigate to quiz rules if quiz is ready (pending status)
                          if (quizData['status'] == 'ready') {
                              print('Navigating to QuizRulesPage...');
                            Navigator.pop(context); // Close the My Races dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizRulesPage(
                                  quizId: quiz.id,
                                  quizData: quizData,
                                ),
                              ),
                            );
                          } else {
                              print('Quiz status is not ready, no navigation');
                          }
                        },
                        child: Container(
                         margin: const EdgeInsets.only(bottom: 16),
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             begin: Alignment.topLeft,
                             end: Alignment.bottomRight,
                             colors: [
                               Colors.white,
                               Colors.grey.shade50,
                             ],
                           ),
                           borderRadius: BorderRadius.circular(20),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.08),
                               blurRadius: 15,
                               offset: const Offset(0, 8),
                               spreadRadius: 0,
                             ),
                             BoxShadow(
                               color: Colors.black.withOpacity(0.04),
                               blurRadius: 6,
                               offset: const Offset(0, 2),
                               spreadRadius: 0,
                             ),
                           ],
                           border: Border.all(
                             color: Colors.grey.shade200,
                             width: 1,
                           ),
                         ),
                         child: Padding(
                           padding: const EdgeInsets.all(20),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                                       gradient: LinearGradient(
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                         colors: quizData['createdBy'] == user?.uid
                                             ? [Colors.orange.shade400, Colors.orange.shade600]
                                             : [const Color(0xFF203E52), const Color(0xFF2A4A5E)],
                                       ),
                                       borderRadius: BorderRadius.circular(16),
                                       boxShadow: [
                                         BoxShadow(
                                           color: (quizData['createdBy'] == user?.uid
                                               ? Colors.orange
                                               : const Color(0xFF203E52)).withOpacity(0.3),
                                           blurRadius: 8,
                                           offset: const Offset(0, 4),
                                         ),
                                       ],
                                     ),
                                     child: Icon(
                                       quizData['createdBy'] == user?.uid
                                           ? Icons.create_rounded
                                           : Icons.group_rounded,
                                       color: Colors.white,
                                       size: 24,
                                     ),
                                   ),
                                   const SizedBox(width: 16),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           quizData['subject'] ?? 'Unknown Subject',
                                           style: const TextStyle(
                                             fontSize: 18,
                                             fontWeight: FontWeight.bold,
                                             color: Color(0xFF203E52),
                                           ),
                                         ),
                                         const SizedBox(height: 4),
                                         Container(
                                           padding: const EdgeInsets.symmetric(
                                             horizontal: 12,
                                             vertical: 4,
                                           ),
                                           decoration: BoxDecoration(
                                             color: const Color(0xFF203E52).withOpacity(0.1),
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: Text(
                                             quizData['level'] ?? 'Unknown Level',
                                             style: const TextStyle(
                                               fontSize: 14,
                                               fontWeight: FontWeight.w600,
                                               color: Color(0xFF203E52),
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                   Container(
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 12,
                                       vertical: 6,
                                     ),
                                     decoration: BoxDecoration(
                                       gradient: LinearGradient(
                                         colors: _getStatusGradient(quizData['status']),
                                       ),
                                       borderRadius: BorderRadius.circular(20),
                                       boxShadow: [
                                         BoxShadow(
                                           color: _getStatusColor(quizData['status']).withOpacity(0.3),
                                           blurRadius: 6,
                                           offset: const Offset(0, 3),
                                         ),
                                       ],
                                     ),
                                     child: Text(
                                       (quizData['status'] ?? 'pending').toUpperCase(),
                                       style: const TextStyle(
                                         fontSize: 11,
                                         fontWeight: FontWeight.bold,
                                         color: Colors.white,
                                         letterSpacing: 0.5,
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                               const SizedBox(height: 16),
                               Container(
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: Colors.grey.shade50,
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(
                                     color: Colors.grey.shade200,
                                     width: 1,
                                   ),
                                 ),
                                 child: Row(
                                   children: [
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             children: [
                                               Icon(
                                                 Icons.qr_code_rounded,
                                                 size: 16,
                                                 color: Colors.grey.shade600,
                                               ),
                                               const SizedBox(width: 6),
                                               Text(
                                                 'Quiz Code',
                                                 style: TextStyle(
                                                   fontSize: 12,
                                                   color: Colors.grey.shade600,
                                                   fontWeight: FontWeight.w500,
                                                 ),
                                               ),
                                             ],
                                           ),
                                           const SizedBox(height: 4),
                                           Text(
                                             quizData['quizCode'] ?? 'N/A',
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
                                     Container(
                                       width: 1,
                                       height: 40,
                                       color: Colors.grey.shade300,
                                     ),
                                     const SizedBox(width: 16),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             children: [
                                               Icon(
                                                 Icons.people_rounded,
                                                 size: 16,
                                                 color: Colors.grey.shade600,
                                               ),
                                               const SizedBox(width: 6),
                                               Text(
                                                 'Participants',
                                                 style: TextStyle(
                                                   fontSize: 12,
                                                   color: Colors.grey.shade600,
                                                   fontWeight: FontWeight.w500,
                                                 ),
                                               ),
                                             ],
                                           ),
                                           const SizedBox(height: 4),
                                           Row(
                                             children: [
                                               Text(
                                                 '${(quizData['participants'] as List).length}',
                                                 style: const TextStyle(
                                                   fontSize: 16,
                                                   fontWeight: FontWeight.bold,
                                                   color: Color(0xFF203E52),
                                                 ),
                                               ),
                                               Text(
                                                 '/${quizData['maxParticipants']}',
                                                 style: TextStyle(
                                                   fontSize: 14,
                                                   color: Colors.grey.shade600,
                                                 ),
                                               ),
                                               const SizedBox(width: 8),
                                               Expanded(
                                                 child: LinearProgressIndicator(
                                                   value: (quizData['participants'] as List).length / quizData['maxParticipants'],
                                                   backgroundColor: Colors.grey.shade300,
                                                   valueColor: AlwaysStoppedAnimation<Color>(
                                                     (quizData['participants'] as List).length == quizData['maxParticipants']
                                                         ? Colors.green
                                                         : Colors.orange,
                                                   ),
                                                   borderRadius: BorderRadius.circular(4),
                                                 ),
                                               ),
                                             ],
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
                        ));
                    });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  List<Color> _getStatusGradient(String? status) {
    switch (status) {
      case 'active':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'completed':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'pending':
      default:
        return [Colors.orange.shade400, Colors.orange.shade600];
    }
  }
}

class CreateQuizDialog extends StatefulWidget {
  const CreateQuizDialog({super.key});

  @override
  State<CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends State<CreateQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubject;
  String? _selectedLevel;
  int _maxParticipants = 2;
  bool _isCreating = false;

  final List<String> _subjects = [
    'Mathematics',
    'English',
    'Science',
    'Social Studies',
    'Religious Education',
    'Agriculture',
    'Art',
    'Music',
    'Physical Education',
  ];

  final Map<String, List<String>> _levels = {
    'Primary': ['P.1', 'P.2', 'P.3', 'P.4', 'P.5', 'P.6', 'P.7'],
    'Secondary': ['S.1', 'S.2', 'S.3', 'S.4', 'S.5', 'S.6'],
    'Advanced': ['A-Level'],
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Create Quiz',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF203E52),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSubject,
                items: _subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                 decoration: const InputDecoration(
                   labelText: 'Level',
                   border: OutlineInputBorder(),
                 ),
                 value: _selectedLevel,
                 items: _levels.entries.expand((entry) {
                   return entry.value.map((level) {
                     return DropdownMenuItem<String>(
                       value: level,
                       child: Text('${entry.key} - $level'),
                     );
                   });
                 }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Max Participants: '),
                  Expanded(
                    child: Slider(
                      value: _maxParticipants.toDouble(),
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: _maxParticipants.toString(),
                      onChanged: (value) {
                        setState(() {
                          _maxParticipants = value.round();
                        });
                      },
                    ),
                  ),
                  Text(_maxParticipants.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate quiz code
      final quizCode = _generateQuizCode();

      // Create quiz document
      final docRef = await FirebaseFirestore.instance.collection('quizzes').add({
        'quizCode': quizCode,
        'subject': _selectedSubject,
        'level': _selectedLevel,
        'maxParticipants': _maxParticipants,
        'participants': [user.uid],
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'generating_questions',
        'questionsGenerated': false,
      });

      // Call API to generate questions
      await _generateQuestions(docRef.id, _selectedSubject!, _selectedLevel!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz created! Code: $quizCode\nGenerating questions...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Copy to clipboard
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  String _generateQuizCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _generateQuestions(String quizId, String subject, String level) async {
    try {
      const apiUrl = 'https://quiz-tan-xi.vercel.app/generate-questions';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quiz_id': quizId,
          'subject': subject,
          'level': level,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Questions generated successfully: ${responseData['questions_count']} questions');
      } else {
        throw Exception('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling question generation API: $e');
      // Update quiz status to indicate error
      try {
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizId)
            .update({
          'status': 'error',
          'error': 'Failed to generate questions: $e',
        });
      } catch (updateError) {
        print('Error updating quiz status: $updateError');
      }
    }
  }
}

class JoinQuizDialog extends StatefulWidget {
  const JoinQuizDialog({super.key});

  @override
  State<JoinQuizDialog> createState() => _JoinQuizDialogState();
}

class _JoinQuizDialogState extends State<JoinQuizDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Join Quiz',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF203E52),
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Quiz Code',
                border: OutlineInputBorder(),
                hintText: 'Enter 6-character code',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quiz code';
                }
                if (value.length != 6) {
                  return 'Quiz code must be 6 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isJoining ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isJoining ? null : _joinQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF203E52),
            foregroundColor: Colors.white,
          ),
          child: _isJoining
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Join'),
        ),
      ],
    );
  }

  Future<void> _joinQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final quizCode = _codeController.text.toUpperCase();

      // Find quiz by code
      final querySnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('quizCode', isEqualTo: quizCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Quiz not found');
      }

      final quizDoc = querySnapshot.docs.first;
      final quizData = quizDoc.data();
      final participants = List<String>.from(quizData['participants'] ?? []);

      if (participants.contains(user.uid)) {
        throw Exception('You are already in this quiz');
      }

      if (participants.length >= quizData['maxParticipants']) {
        throw Exception('Quiz is full');
      }

      // if (quizData['status'] != 'pending') {
      //   throw Exception('Quiz has already started or ended');
      // }

      // Add user to participants
      await quizDoc.reference.update({
        'participants': FieldValue.arrayUnion([user.uid]),
      });

      if (mounted) {
        Navigator.pop(context);
        // Navigate to quiz rules page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizRulesPage(
              quizId: quizDoc.id,
              quizData: quizData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

class HistoryBottomSheet extends StatelessWidget {
  const HistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quiz History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203E52),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('quiz_history')
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('completedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quiz history yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete some quizzes to see your history here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final historyItem = snapshot.data!.docs[index];
                      final data = historyItem.data() as Map<String, dynamic>;
                      final percentage = data['percentage'] ?? 0.0;
                      final grade = data['grade'] ?? 'F';
                      
                      MaterialColor gradeColor = Colors.red;
                       if (percentage >= 80) gradeColor = Colors.green;
                       else if (percentage >= 60) gradeColor = Colors.orange;
                       
                       return Container(
                         margin: const EdgeInsets.only(bottom: 16),
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             begin: Alignment.topLeft,
                             end: Alignment.bottomRight,
                             colors: [
                               Colors.white,
                               Colors.grey.shade50,
                             ],
                           ),
                           borderRadius: BorderRadius.circular(20),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.08),
                               blurRadius: 15,
                               offset: const Offset(0, 8),
                               spreadRadius: 0,
                             ),
                           ],
                           border: Border.all(
                             color: Colors.grey.shade200,
                             width: 1,
                           ),
                         ),
                         child: Padding(
                           padding: const EdgeInsets.all(20),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                                       gradient: LinearGradient(
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                         colors: [gradeColor.shade400, gradeColor.shade600],
                                       ),
                                       borderRadius: BorderRadius.circular(16),
                                       boxShadow: [
                                         BoxShadow(
                                           color: gradeColor.withOpacity(0.3),
                                           blurRadius: 8,
                                           offset: const Offset(0, 4),
                                         ),
                                       ],
                                     ),
                                    child: const Icon(
                                      Icons.quiz_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['subject'] ?? 'Unknown Subject',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF203E52),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Level: ${data['level'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gradeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: gradeColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      grade,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: gradeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Score',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${data['score']}/${data['totalQuestions']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF203E52),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Percentage',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF203E52),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        data['completedAt'] != null
                                            ? _formatDate(data['completedAt'])
                                            : 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF203E52),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Unknown';
    }
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}