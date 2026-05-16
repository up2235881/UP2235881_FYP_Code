import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'review_summary_page.dart';

class ReviewPage extends StatefulWidget {
  final String unitId;
  final String unitTitle;

  const ReviewPage({
    super.key,
    required this.unitId,
    required this.unitTitle,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final AudioPlayer _player = AudioPlayer();

  Future<Map<String, dynamic>> _loadReview() async {
    final reviewSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('unitId', isEqualTo: widget.unitId)
        .where('published', isEqualTo: true)
        .limit(1)
        .get();

    if (reviewSnap.docs.isEmpty) {
      throw Exception('No review found.');
    }

    final reviewData = reviewSnap.docs.first.data();

    final phrasesSnap = await FirebaseFirestore.instance
        .collection('phrases')
        .where('unitId', isEqualTo: widget.unitId)
        .get();

    final phrases = phrasesSnap.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    return {
      'review': reviewData,
      'phrases': phrases,
    };
  }

  Future<void> _playAudio(String? audioUrl) async {
    final url = audioUrl?.trim();

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio found.')),
      );
      return;
    }

    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text('${widget.unitTitle} Review'),
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadReview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error:\n${snapshot.error}'));
          }

          final review = snapshot.data!['review'] as Map<String, dynamic>;
          final phrases =
          snapshot.data!['phrases'] as List<Map<String, dynamic>>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                review['title'] ?? 'Review',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(review['description'] ?? ''),
              const SizedBox(height: 18),

              ...phrases.map((phrase) {
                return Card(
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.play_circle),
                      onPressed: () => _playAudio(phrase['audioUrl']),
                    ),
                    title: Text(
                      phrase['roman'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          phrase['english'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          phrase['gurmukhi'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: () async {
                  final points = review['lassiPoints'] ?? 0;
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'reviewsCompleted': FieldValue.arrayUnion(['review_${widget.unitId}']),
                      'totalPoints': FieldValue.increment(points),
                    }, SetOptions(merge: true));
                  }

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewSummaryPage(
                        unitTitle: widget.unitTitle,
                        lassiPoints: points,
                      ),
                    ),
                  );
                },
                child: const Text('Done Reviewing'),
              ),
            ],
          );
        },
      ),
    );
  }
}