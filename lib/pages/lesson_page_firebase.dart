import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/firebase_exercise.dart';
import '../widgets/exercise_screen.dart';
import 'lesson_summary_page.dart';


class LessonPageFirebase extends StatefulWidget {
  final String unitId;
  final String unitTitle;
  final String lessonId;
  final String lessonTitle;
  final int lassiPoints;


  const LessonPageFirebase({
    super.key,
    required this.unitId,
    required this.unitTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.lassiPoints,
  });


  @override
  State<LessonPageFirebase> createState() => _LessonPageFirebaseState();
}


class _LessonPageFirebaseState extends State<LessonPageFirebase> {
  int index = 0;
  late final Future<List<FirebaseExercise>> _future;


  @override
  void initState() {
    super.initState();
    _future = _loadExercises();
  }


  Future<List<FirebaseExercise>> _loadExercises() async {
    final linksSnap = await FirebaseFirestore.instance
        .collection('lessons')
        .doc(widget.lessonId)
        .collection('lessonExercises')
        .orderBy('order')
        .get();


    final ids = linksSnap.docs.map((d) => d['exerciseId'] as String).toList();

    if (ids.isEmpty) return [];

    final exDocs = await Future.wait(
      ids.map((id) =>
          FirebaseFirestore.instance.collection('exercises').doc(id).get()),
    );


    final exercises = <FirebaseExercise>[];
    for (final doc in exDocs) {
      if (!doc.exists || doc.data() == null) continue;

      final exerciseData = doc.data()!;

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

    // Keep order from links
    exercises.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return exercises;
  }


  Future<void> _next(int total, List<FirebaseExercise> exercises) async {
    if (index < total - 1) {
      setState(() => index++);
    } else {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'totalPoints': FieldValue.increment(widget.lassiPoints),
          'lessonsCompleted': FieldValue.arrayUnion([widget.lessonId]),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonSummaryPage(
            unitTitle: widget.unitTitle,
            lessonTitle: widget.lessonTitle,
            exercises: exercises,
            lassiPoints: widget.lassiPoints,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar:
      AppBar(title: Text('${widget.unitTitle} • ${widget.lessonTitle}'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,),
      body: FutureBuilder<List<FirebaseExercise>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error:\n${snapshot.error}'));
          }


          final exercises = snapshot.data ?? [];
          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises found for this lesson.'));
          }


          if (index >= exercises.length) index = 0;
          final ex = exercises[index];


          return ExerciseScreen(
            exercise: ex,
            progress: (index + 1) / exercises.length,
            isLast: index == exercises.length - 1,
            onNext: (isCorrect) => _next(exercises.length, exercises),
          );
        },
      ),
    );
  }
}