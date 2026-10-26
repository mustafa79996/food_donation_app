import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputButton extends StatelessWidget {
  const VoiceInputButton({
    super.key,
    required this.label,
    this.controller,
    this.onResult,
    this.icon = Icons.mic_none,
    this.accentColor,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onResult;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return _VoiceInputControl(
      label: label,
      controller: controller,
      onResult: onResult,
      icon: icon,
      accentColor: accentColor,
    );
  }
}

class VoiceInputIconButton extends StatelessWidget {
  const VoiceInputIconButton({
    super.key,
    this.controller,
    this.onResult,
    this.tooltip = 'Voice search',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onResult;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return _VoiceInputControl(
      controller: controller,
      onResult: onResult,
      tooltip: tooltip,
    );
  }
}

class _VoiceInputControl extends StatefulWidget {
  const _VoiceInputControl({
    this.label,
    this.controller,
    this.onResult,
    this.icon = Icons.mic_none,
    this.accentColor,
    this.tooltip = 'Voice input',
  });

  final String? label;
  final TextEditingController? controller;
  final ValueChanged<String>? onResult;
  final IconData icon;
  final Color? accentColor;
  final String tooltip;

  @override
  State<_VoiceInputControl> createState() => _VoiceInputControlState();
}

class _VoiceInputControlState extends State<_VoiceInputControl> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  Future<void> _toggleListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        if (mounted) setState(() => _isListening = false);
        return;
      }

      if (!_isAvailable) {
        _isAvailable = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            setState(() => _isListening = status == 'listening');
          },
          onError: (error) {
            if (!mounted) return;
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice recognition error: ${error.errorMsg}'),
              ),
            );
          },
        );
      }

      if (!_isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice recognition is unavailable. Check microphone permissions and device speech services.',
            ),
          ),
        );
        return;
      }

      setState(() => _isListening = true);
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          partialResults: false,
        ),
        onResult: (result) {
          if (!mounted) return;
          final value = result.recognizedWords.trim();
          if (value.isNotEmpty) {
            final controller = widget.controller;
            if (controller != null) {
              controller.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            }
            widget.onResult?.call(value);
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to capture voice input: $error')),
      );
    }
  }

  @override
  void dispose() {
    if (_speech.isListening) unawaited(_speech.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(_isListening ? Icons.mic : widget.icon);
    final label = widget.label;

    if (label == null) {
      return IconButton(
        tooltip: _isListening ? 'Stop listening' : widget.tooltip,
        icon: icon,
        onPressed: _toggleListening,
      );
    }

    return FilledButton.icon(
      onPressed: _toggleListening,
      icon: icon,
      label: Text(_isListening ? 'Listening...' : label),
      style: FilledButton.styleFrom(
        backgroundColor:
            widget.accentColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
