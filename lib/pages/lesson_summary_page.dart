import 'package:flutter/material.dart';
import '../models/firebase_exercise.dart';

class LessonSummaryPage extends StatelessWidget {
  final String unitTitle;
  final String lessonTitle;
  final int lassiPoints;
  final List<FirebaseExercise> exercises;

  const LessonSummaryPage({
    super.key,
    required this.unitTitle,
    required this.lessonTitle,
    required this.exercises,
    required this.lassiPoints,
  });

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};

    final phrases = exercises
        .where((e) => e.english.isNotEmpty)
        .where((e) {
      final key = '${e.gurmukhi}|${e.roman}|${e.english}';
      return seen.add(key);
    })
        .toList();

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Lesson Summary'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.orange.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      '$lessonTitle completed!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Here is a quick recap of what you learned.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_drink, color: Colors.orange),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+$lassiPoints Lassi Points',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.local_drink,
                                color: Colors.orange.shade800,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: phrases.length,
                itemBuilder: (context, index) {
                  final phrase = phrases[index];

                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(
                        phrase.roman,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${phrase.english}\n${phrase.gurmukhi}',
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                ),
                onPressed: () {
                  Navigator.pop(context); // summary page
                  Navigator.pop(context); // lesson page
                },
                child: const Text('Finish Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}