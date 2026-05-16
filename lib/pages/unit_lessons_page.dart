import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lesson_page_firebase.dart';
import 'review_page.dart';
import 'exam_page.dart';

class UnitLessonsPage extends StatelessWidget {
  final String unitId;
  final String unitTitle;

  const UnitLessonsPage({
    super.key,
    required this.unitId,
    required this.unitTitle,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final lessonsStream = FirebaseFirestore.instance
        .collection('lessons')
        .where('unitId', isEqualTo: unitId)
        .where('published', isEqualTo: true)
        .orderBy('order')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(unitTitle),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user == null
            ? null
            : FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

          final completedLessons =
          List<String>.from(userData?['lessonsCompleted'] ?? []);

          final completedReviews =
          List<String>.from(userData?['reviewsCompleted'] ?? []);

          final completedExams =
          List<String>.from(userData?['examsCompleted'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: lessonsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error:\n${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final lessons = snapshot.data!.docs;

              if (lessons.isEmpty) {
                return const Center(child: Text('No lessons found.'));
              }

              final allLessonsCompleted = lessons.every(
                    (lessonDoc) => completedLessons.contains(lessonDoc.id),
              );

              final reviewId = 'review_$unitId';
              final reviewCompleted = completedReviews.contains(reviewId);
              final reviewUnlocked = allLessonsCompleted;

              final examId = 'exam_$unitId';
              final examCompleted = completedExams.contains(examId);
              final examUnlocked = reviewCompleted;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lessons.length + 2,
                itemBuilder: (context, i) {
                  if (i == lessons.length) {
                    return Opacity(
                      opacity: reviewUnlocked ? 1.0 : 0.45,
                      child: Card(
                        color: Colors.orange.shade100,
                        elevation: reviewUnlocked ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Icon(
                            reviewCompleted
                                ? Icons.check_circle
                                : reviewUnlocked
                                ? Icons.replay
                                : Icons.lock,
                            color: reviewCompleted
                                ? Colors.green
                                : reviewUnlocked
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          title: const Text('Review'),
                          subtitle: Text(
                            reviewUnlocked
                                ? 'Recap everything learned in this unit'
                                : 'Complete all lessons to unlock review',
                          ),
                          trailing: Icon(
                            reviewUnlocked
                                ? Icons.arrow_forward
                                : Icons.lock,
                          ),
                          onTap: reviewUnlocked
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewPage(
                                  unitId: unitId,
                                  unitTitle: unitTitle,
                                ),
                              ),
                            );
                          }
                              : null,
                        ),
                      ),
                    );
                  }

                  if (i == lessons.length + 1) {
                    return Opacity(
                      opacity: examUnlocked ? 1.0 : 0.45,
                      child: Card(
                        color: Colors.orange.shade100,
                        elevation: examUnlocked ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Icon(
                            examCompleted
                                ? Icons.check_circle
                                : examUnlocked
                                ? Icons.quiz
                                : Icons.lock,
                            color: examCompleted
                                ? Colors.green
                                : examUnlocked
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          title: const Text('Exam'),
                          subtitle: Text(
                            examUnlocked
                                ? 'Complete the exam to finish this unit'
                                : 'Complete the review to unlock exam',
                          ),
                          trailing: Icon(
                            examUnlocked
                                ? Icons.arrow_forward
                                : Icons.lock,
                          ),
                          onTap: examUnlocked
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamPage(
                                  unitId: unitId,
                                  unitTitle: unitTitle,
                                ),
                              ),
                            );
                          }
                              : null,
                        ),
                      ),
                    );
                  }

                  final doc = lessons[i];
                  final lessonId = doc.id;
                  final lesson = doc.data() as Map<String, dynamic>;

                  final title = lesson['title'] ?? 'Lesson';
                  final description = lesson['description'] ?? '';
                  final lassiPoints = lesson['lassiPoints'] ?? 0;

                  final isCompleted =
                  completedLessons.contains(lessonId);

                  final isUnlocked = i == 0 ||
                      completedLessons.contains(lessons[i - 1].id);

                  return Opacity(
                    opacity: isUnlocked ? 1.0 : 0.45,
                    child: Card(
                      color: Colors.orange.shade100,
                      elevation: isUnlocked ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isUnlocked
                              ? Icons.play_circle
                              : Icons.lock,
                          color: isCompleted
                              ? Colors.green
                              : isUnlocked
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        title: Text(title),
                        subtitle: Text(
                          isUnlocked
                              ? description
                              : 'Complete the previous lesson to unlock',
                        ),
                        trailing: Icon(
                          isUnlocked
                              ? Icons.arrow_forward
                              : Icons.lock,
                        ),
                        onTap: isUnlocked
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonPageFirebase(
                                unitId: unitId,
                                unitTitle: unitTitle,
                                lessonId: lessonId,
                                lessonTitle: title,
                                lassiPoints: lassiPoints,
                              ),
                            ),
                          );
                        }
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}