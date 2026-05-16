import 'package:flutter/material.dart';

class ExamSummaryPage extends StatelessWidget {
  final String unitTitle;
  final int score;
  final int passMark;
  final int lassiPoints;
  final bool passed;

  const ExamSummaryPage({
    super.key,
    required this.unitTitle,
    required this.score,
    required this.passMark,
    required this.lassiPoints,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Exam Complete'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: passed ? Colors.orange.shade100 : Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      passed ? Icons.celebration : Icons.refresh,
                      size: 56,
                      color: passed ? Colors.orange.shade800 : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      passed ? 'You passed!' : 'Try again',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Score: $score%\nPass mark: $passMark%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (passed) ...[
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 8),
                      const Text(
                        'The next unit has been unlocked.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                ),
                onPressed: () {
                  Navigator.pop(context); // summary
                  Navigator.pop(context); // exam page
                },
                child: Text(passed ? 'Continue' : 'Back to Unit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}