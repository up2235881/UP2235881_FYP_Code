import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/firebase_exercise.dart';

class McqExercise extends StatefulWidget {
  final FirebaseExercise exercise;
  final void Function(bool isCorrect) onNext;
  final bool isLast;

  const McqExercise({
    super.key,
    required this.exercise,
    required this.onNext,
    required this.isLast,
  });

  @override
  State<McqExercise> createState() => _McqExerciseState();
}

class _McqExerciseState extends State<McqExercise> {
  String? selected;
  bool? isCorrect;
  final AudioPlayer _player = AudioPlayer();

  Future<void> _playAudio() async {
    final url = widget.exercise.audioUrl?.trim();

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

  void _check(String option) {
    final correct = widget.exercise.correctAnswer;
    setState(() {
      selected = option;
      isCorrect = correct != null && option == correct;
    });
  }

  Color? _getOptionColor(String option) {
    if (isCorrect == null) return null;

    final correct = widget.exercise.correctAnswer;

    if (option == correct) {
      return Colors.green.shade300; // correct answer
    }

    if (option == selected && option != correct) {
      return Colors.red.shade300; // wrong selection
    }

    return null;
  }

  @override
  void didUpdateWidget(covariant McqExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      selected = null;
      isCorrect = null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;

    if (ex.options.isEmpty || ex.correctAnswer == null) {
      return const Center(
        child: Text('MCQ is missing options/correctAnswer in Firestore.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ex.question.isNotEmpty
              ? ex.question
              : 'Listen and choose the correct answer.',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        Center(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            onPressed: _playAudio,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play audio'),
          ),
        ),

        const SizedBox(height: 18),

        Expanded(
          child: ListView(
            children: ex.options.map((opt) {
              final chosen = selected == opt;
              final locked = isCorrect != null;

              return Card(
                color: _getOptionColor(opt) ?? Colors.white,
                elevation: 2,
                child: InkWell(
                  onTap: locked ? null : () => _check(opt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            onPressed:
            isCorrect == null ? null : () => widget.onNext(isCorrect!),
            child: Text(widget.isLast ? 'Finish' : 'Next'),
          ),
        ),
      ],
    );
  }
}