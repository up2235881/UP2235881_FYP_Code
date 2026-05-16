import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseType { listenRead, mcq }

ExerciseType parseExerciseType(String raw) {
  switch (raw) {
    case 'mcq':
      return ExerciseType.mcq;
    case 'listenRead':
    default:
      return ExerciseType.listenRead;
  }
}

class FirebaseExercise {
  final String id;
  final ExerciseType type;

  final String phraseId;
  final String question;
  final int points;

  final String gurmukhi;
  final String roman;
  final String english;
  final String? audioUrl;

  final List<String> options;
  final String? correctAnswer;

  FirebaseExercise({
    required this.id,
    required this.type,
    required this.phraseId,
    required this.question,
    required this.points,
    required this.gurmukhi,
    required this.roman,
    required this.english,
    this.audioUrl,
    this.options = const [],
    this.correctAnswer,
  });

  factory FirebaseExercise.fromExerciseAndPhrase({
    required String id,
    required Map<String, dynamic> exerciseData,
    required Map<String, dynamic> phraseData,
  }) {
    final rawType =
    (exerciseData['type'] ?? exerciseData['exerciseType'] ?? 'listenRead') as String;

    final optionsRaw = exerciseData['options'];
    final options =
    (optionsRaw is List) ? List<String>.from(optionsRaw) : <String>[];

    return FirebaseExercise(
      id: id,
      type: parseExerciseType(rawType),
      phraseId: exerciseData['phraseId'] ?? exerciseData['phraseID'] ?? '',
      question: exerciseData['question'] ?? '',
      points: exerciseData['points'] ?? 0,

      gurmukhi: phraseData['gurmukhi'] ?? '',
      roman: phraseData['roman'] ?? '',
      english: phraseData['english'] ?? '',
      audioUrl: phraseData['audioUrl'],

      options: options,
      correctAnswer: exerciseData['correctAnswer'],
    );
  }
}



      
