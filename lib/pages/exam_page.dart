import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/firebase_exercise.dart';
import '../widgets/exercise_screen.dart';

import 'exam_summary_page.dart';

class ExamPage extends StatefulWidget {
  final String unitId;
  final String unitTitle;

  const ExamPage({
    super.key,
    required this.unitId,
    required this.unitTitle,
  });

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  int index = 0;
  int correctAnswers = 0;
  bool _finishing = false;

  late final Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadExam();
  }

  Future<Map<String, dynamic>> _loadExam() async {
    final examSnap = await FirebaseFirestore.instance
        .collection('exams')
        .where('unitId', isEqualTo: widget.unitId)
        .where('published', isEqualTo: true)
        .limit(1)
        .get();

    if (examSnap.docs.isEmpty) {
      throw Exception('No exam found.');
    }

    final examDoc = examSnap.docs.first;
    final examData = examDoc.data();
    final mcqCount = examData['mcqCount'] ?? 5;
    final speakingCount = examData['speakingCount'] ?? 3;

    final exercisesSnap = await FirebaseFirestore.instance
        .collection('exercises')
        .where('unitId', isEqualTo: widget.unitId)
        .get();

    final allExerciseDocs = exercisesSnap.docs.toList();

    final speakingDocs = allExerciseDocs.where((doc) {
      final data = doc.data();
      final type = data['exerciseType']?.toString().toLowerCase();
      return type == 'listenread';
    }).toList();

    final mcqDocs = allExerciseDocs.where((doc) {
      final data = doc.data();
      final type = data['exerciseType']?.toString().toLowerCase();
      return type == 'mcq';
    }).toList();

    speakingDocs.shuffle();
    mcqDocs.shuffle();

    final selectedDocs = [
      ...speakingDocs.take(speakingCount),
      ...mcqDocs.take(mcqCount),
    ]..shuffle();

    final exercises = <FirebaseExercise>[];

    for (final doc in selectedDocs) {
      final exerciseData = doc.data();
      final phraseId = exerciseData['phraseId'] ?? exerciseData['phraseID'];

      if (phraseId == null || phraseId.toString().isEmpty) continue;

      final phraseDoc = await FirebaseFirestore.instance
          .collection('phrases')
          .doc(phraseId.toString())
          .get();

      if (!phraseDoc.exists || phraseDoc.data() == null) continue;

      exercises.add(
        FirebaseExercise.fromExerciseAndPhrase(
          id: doc.id,
          exerciseData: exerciseData,
          phraseData: phraseDoc.data()!,
        ),
      );
    }

    return {
      'examId': examDoc.id,
      'exam': examData,
      'exercises': exercises,
    };
  }

  Future<void> _savePassedProgress({
    required int score,
    required int lassiPoints,
    required String examId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? nextUnitId;

    final currentUnitDoc = await FirebaseFirestore.instance
        .collection('units')
        .doc(widget.unitId)
        .get();

    final currentOrder = currentUnitDoc.data()?['order'];

    if (currentOrder is num) {
      final nextUnitSnap = await FirebaseFirestore.instance
          .collection('units')
          .where('published', isEqualTo: true)
          .where('order', isGreaterThan: currentOrder)
          .orderBy('order')
          .limit(1)
          .get();

      if (nextUnitSnap.docs.isNotEmpty) {
        nextUnitId = nextUnitSnap.docs.first.id;
      }
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userRef.set({
      'completedUnits': FieldValue.arrayUnion([widget.unitId]),
      'completedExams': FieldValue.arrayUnion([examId]),
      'examScores': {examId: score},
      'totalPoints': FieldValue.increment(lassiPoints),
      'updatedAt': FieldValue.serverTimestamp(),
      if (nextUnitId != null)
        'unlockedUnits': FieldValue.arrayUnion([nextUnitId]),
    }, SetOptions(merge: true));
  }

  Future<void> _next({
    required bool isCorrect,
    required int total,
    required int passMark,
    required int lassiPoints,
    required String examId,
  }) async {
    if (_finishing) return;

    if (isCorrect) correctAnswers++;

    if (index < total - 1) {
      setState(() => index++);
      return;
    }

    setState(() => _finishing = true);

    final score = ((correctAnswers / total) * 100).round();
    final passed = score >= passMark;

    if (passed) {
      await _savePassedProgress(
        score: score,
        lassiPoints: lassiPoints,
        examId: examId,
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamSummaryPage(
          unitTitle: widget.unitTitle,
          score: score,
          passMark: passMark,
          lassiPoints: lassiPoints,
          passed: passed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.orange.shade50,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.orange.shade50,
            appBar: AppBar(title: const Text('Exam'),
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,),
            body: Center(child: Text('Error:\n${snapshot.error}')),
          );
        }

        final examId = snapshot.data!['examId'] as String;
        final exam = snapshot.data!['exam'] as Map<String, dynamic>;
        final exercises = snapshot.data!['exercises'] as List<FirebaseExercise>;

        final passMark = exam['passMark'] ?? 70;
        final lassiPoints = exam['lassiPoints'] ?? 0;

        if (exercises.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.orange.shade50,
            appBar: AppBar(title: const Text('Exam'),
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,),
            body: const Center(child: Text('No exam exercises found.')),
          );
        }

        final exercise = exercises[index];

        return Scaffold(
          backgroundColor: Colors.orange.shade50,
          appBar: AppBar(
            title: Text(exam['title'] ?? '${widget.unitTitle} Exam'),
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
          ),
          body: AbsorbPointer(
            absorbing: _finishing,
            child: ExerciseScreen(
              exercise: exercise,
              progress: (index + 1) / exercises.length,
              isLast: index == exercises.length - 1,
              examMode: true,
              onNext: (isCorrect) => _next(
                isCorrect: isCorrect,
                total: exercises.length,
                passMark: passMark,
                lassiPoints: lassiPoints,
                examId: examId,
              ),
            ),
          ),
        );
      },
    );
  }
}