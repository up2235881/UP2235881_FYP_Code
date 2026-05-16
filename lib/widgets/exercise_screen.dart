import 'package:flutter/material.dart';

import '../models/firebase_exercise.dart';
import 'listen_read_exercise.dart';
import 'mcq_exercise.dart';

class ExerciseScreen extends StatelessWidget {
  final FirebaseExercise exercise;
  final double progress;
  final bool isLast;
  final void Function(bool isCorrect) onNext;
  final bool examMode;

  const ExerciseScreen({
    super.key,
    required this.exercise,
    required this.progress,
    required this.isLast,
    required this.onNext,
    this.examMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: progress,
            color: Colors.orange.shade600,
            backgroundColor: Colors.orange.shade100,
          ),
          const SizedBox(height: 18),

          if (exercise.type == ExerciseType.listenRead && examMode) ...[
            const Text(
              'Say it in Punjabi:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              exercise.english,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ] else if (exercise.type == ExerciseType.listenRead) ...[
            Text(
              exercise.roman,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              exercise.english,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Text(
              exercise.gurmukhi,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          Expanded(
            child: switch (exercise.type) {
              ExerciseType.listenRead => ListenReadExercise(
                key: ValueKey('lr_${exercise.id}_$examMode'),
                exercise: exercise,
                onNext: onNext,
                isLast: isLast,
                examMode: examMode,
              ),
              ExerciseType.mcq => McqExercise(
                key: ValueKey('mcq_${exercise.id}'),
                exercise: exercise,
                onNext: onNext,
                isLast: isLast,
              ),
            },
          ),
        ],
      ),
    );
  }
}