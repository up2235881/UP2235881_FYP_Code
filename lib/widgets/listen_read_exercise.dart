import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/firebase_exercise.dart';

class ListenReadExercise extends StatefulWidget {
  final FirebaseExercise exercise;
  final void Function(bool isCorrect) onNext;
  final bool isLast;
  final bool examMode;

  const ListenReadExercise({
    super.key,
    required this.exercise,
    required this.onNext,
    required this.isLast,
    this.examMode = false,
  });

  @override
  State<ListenReadExercise> createState() => _ListenReadExerciseState();
}

class _ListenReadExerciseState extends State<ListenReadExercise> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _phrasePlayer = AudioPlayer();
  final AudioPlayer _recordingPlayer = AudioPlayer();

  String? _recordingPath;
  bool _isRecording = false;
  bool _isRecordingPlaying = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String> _newTempRecordingPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/exam_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _playPhraseAudio() async {
    final url = widget.exercise.audioUrl?.trim();

    if (url == null || url.isEmpty) {
      _snack('No phrase audio found.');
      return;
    }

    try {
      await _recordingPlayer.stop();
      await _phrasePlayer.stop();
      await _phrasePlayer.seek(Duration.zero);
      await _phrasePlayer.setUrl(url);
      await _phrasePlayer.play();
    } catch (e) {
      _snack('Phrase audio error: $e');
    }
  }

  Future<void> _startRecording() async {
    final hasPerm = await _recorder.hasPermission();

    if (!hasPerm) {
      _snack('Microphone permission not granted.');
      return;
    }

    await _phrasePlayer.stop();
    await _recordingPlayer.stop();

    final path = await _newTempRecordingPath();
    _recordingPath = path;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    setState(() => _isRecording = false);

    if (path == null) {
      _snack('Recording failed to save.');
      _recordingPath = null;
      return;
    }

    _recordingPath = path;
    _snack('Recorded! Tap Playback to listen.');
  }

  Future<void> _togglePlayback() async {
    final path = _recordingPath;

    if (path == null || !File(path).existsSync()) {
      _snack('No recording yet. Tap Record first.');
      return;
    }

    if (_isRecording) return;

    try {
      if (_isRecordingPlaying) {
        await _recordingPlayer.stop();
        await _recordingPlayer.seek(Duration.zero);
        setState(() => _isRecordingPlaying = false);
        return;
      }

      await _phrasePlayer.stop();
      await _recordingPlayer.stop();
      await _recordingPlayer.seek(Duration.zero);
      await _recordingPlayer.setFilePath(path);

      setState(() => _isRecordingPlaying = true);

      await _recordingPlayer.play();

      await _recordingPlayer.stop();
      await _recordingPlayer.seek(Duration.zero);

      if (mounted) {
        setState(() => _isRecordingPlaying = false);
      }
    }
      catch (e) {
      _snack('Playback error: $e');
      setState(() => _isRecordingPlaying = false);
    }
  }

  Future<void> _goNext() async {
    if (_isRecording) await _stopRecording();

    await _phrasePlayer.stop();
    await _recordingPlayer.stop();

    // For now, listen/read exam questions are marked as correct once attempted.
    widget.onNext(true);
  }

  @override
  void dispose() {
    _phrasePlayer.dispose();
    _recordingPlayer.dispose();
    _recorder.dispose();

    final path = _recordingPath;
    if (path != null) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordLabel = _isRecording ? 'Stop' : 'Record\nyourself';
    final playbackLabel = _isRecordingPlaying ? 'Stop' : 'Playback';

    return Column(
      children: [
        if (!widget.examMode) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Center(
              child: FilledButton.icon(
                onPressed: _playPhraseAudio,
                icon: Icon(Icons.play_arrow),
                label: Text('Play audio'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                IconButton(
                  iconSize: 52,
                  onPressed: (_phrasePlayer.playing || _recordingPlayer.playing)
                      ? null
                      : (_isRecording ? _stopRecording : _startRecording),
                  icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic),
                ),
                const SizedBox(height: 6),
                Text(recordLabel, textAlign: TextAlign.center),
              ],
            ),

            Column(
              children: [
                IconButton(
                  iconSize: 52,
                  onPressed: _isRecording ? null : _togglePlayback,
                  icon: Icon(
                    _isRecordingPlaying
                        ? Icons.stop_circle
                        : Icons.play_arrow,
                  ),
                ),
                const SizedBox(height: 6),
                Text(playbackLabel, textAlign: TextAlign.center),
              ],
            ),
          ],
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            onPressed: _goNext,
            child: Text(widget.isLast ? 'Finish' : 'Next'),
          ),
        ),
      ],
    );
  }
}