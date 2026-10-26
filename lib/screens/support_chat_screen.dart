import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/support_chat_responder.dart';
import '../utils/voice_input.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <({bool fromUser, String text})>[
    (
      fromUser: false,
      text:
          "Hi! I'm your FoodLink assistant. Ask me about donating food, finding a centre, or getting help with a centre application.",
    ),
  ];

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _callSupport() async {
    final phoneController = TextEditingController(text: '+91');
    final number = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Call support'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Support phone number',
            hintText: '+91 98765 43210',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, phoneController.text.trim()),
            child: const Text('Call'),
          ),
        ],
      ),
    );
    phoneController.dispose();
    if (!mounted || number == null) return;

    final normalizedNumber = number.replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalizedNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }

    try {
      if (!await launchUrl(Uri(scheme: 'tel', path: normalizedNumber)) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone dialer.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to call support: $error')));
    }
  }

  void _sendMessage([String? suggestedMessage]) {
    final message = (suggestedMessage ?? _messageController.text).trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add((fromUser: true, text: message));
      _messages.add((
        fromUser: false,
        text: SupportChatResponder.replyTo(message),
      ));
      _messageController.clear();
    });
    _scrollToLatestMessage();
  }

  void _startNewChat() {
    setState(() {
      _messages
        ..clear()
        ..add((
          fromUser: false,
          text:
              "Hi! I'm your FoodLink assistant. Ask me about donating food, finding a centre, or getting help with a centre application.",
        ));
    });
    _scrollToLatestMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FoodLink Assistant'),
            Text(
              'Help with food donations and welfare centres',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Start new chat',
            onPressed: _startNewChat,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Call support',
            onPressed: _callSupport,
            icon: const Icon(Icons.call_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final colors = Theme.of(context).colorScheme;
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: message.fromUser
                            ? colors.primaryContainer
                            : colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(
                            message.fromUser ? 18 : 4,
                          ),
                          bottomRight: Radius.circular(
                            message.fromUser ? 4 : 18,
                          ),
                        ),
                      ),
                      child: Text(message.text),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: SupportChatResponder.suggestedQuestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final question = SupportChatResponder.suggestedQuestions[index];
                return ActionChip(
                  label: Text(question.label),
                  onPressed: () => _sendMessage(question.prompt),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask FoodLink Assistant',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  VoiceInputIconButton(
                    tooltip: 'Speak your question',
                    controller: _messageController,
                  ),
                  IconButton(
                    tooltip: 'Send message',
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
