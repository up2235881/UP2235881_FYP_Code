import 'package:flutter/material.dart';

class ReviewSummaryPage extends StatelessWidget {
  final String unitTitle;
  final int lassiPoints;

  const ReviewSummaryPage({
    super.key,
    required this.unitTitle,
    required this.lassiPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Review Complete'),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.replay_circle_filled, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      '$unitTitle review completed!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                  Navigator.pop(context); // review page
                },
                child: const Text('Back to Unit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}