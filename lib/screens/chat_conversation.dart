import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/saved_routine_storage.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  // Set only on recommendation messages, so the bubble can offer "Save"
  final Map<String, dynamic>? routine;
  bool isSaving;
  bool isSaved;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.routine,
    this.isSaving = false,
    this.isSaved = false,
  });
}

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  bool _isLoading = false;

  // Once a recommendation/escalation has been shown, later messages are plain
  // conversation and must not trigger another assessment.
  bool _assessmentShown = false;

  @override
  void initState() {
    super.initState();
    _addBotMessage("Ki ora, I'm Glow! Tell me what's going on with your skin today?");
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {Map<String, dynamic>? routine}) {
    if (!mounted) return;
    setState(() => _messages.add(ChatMessage(text: text, isUser: false, routine: routine)));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Map<String, String>> _buildHistory() {
    return _messages
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    final historyBeforeThisTurn = _buildHistory();
    _addUserMessage(text);
    setState(() => _isLoading = true);

    try {
      // 60s because Render's free tier can take up to a minute to wake up
      final result = await ApiService.sendChatMessage(
        conversationHistory: historyBeforeThisTurn,
        latestMessage: text,
        alreadyAssessed: _assessmentShown,
      ).timeout(const Duration(seconds: 60));

      _addBotMessage(result['reply'] ?? "Let's continue...");

      if (result['ready_to_assess'] == true && result['assessment'] != null) {
        _showAssessmentResult(result['assessment'] as Map<String, dynamic>);
      }
    } on TimeoutException {
      _addBotMessage("The server took too long to respond. Please try again in a moment.");
    } catch (e) {
      _addBotMessage("Sorry, something went wrong. Please try again.");
      debugPrint('Chat error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssessmentResult(Map<String, dynamic> assessment) {
    final status = assessment['status'];

    if (status == 'escalated') {
      _assessmentShown = true;
      _addBotMessage("⚠️ ${assessment['message']}\n\nPlease consult a professional for further guidance.");
    } else if (status == 'follow_up_needed') {
      _addBotMessage(assessment['message'] ?? 'Could you share a bit more detail?');
    } else if (status == 'recommendation') {
      final rec = assessment['recommendation'] as Map<String, dynamic>?;
      if (rec == null) {
        _addBotMessage("Sorry, no recommendation data was returned.");
        return;
      }
      _assessmentShown = true;

      final morning = ((rec['morning_routine'] as List?) ?? []).join(', ');
      final evening = ((rec['evening_routine'] as List?) ?? []).join(', ');
      final confidenceValue = assessment['confidence'];
      final confidencePercent =
      confidenceValue != null ? ((confidenceValue as num) * 100).round() : 0;

      _addBotMessage(
        "🌞 Morning: ${morning.isEmpty ? 'N/A' : morning}\n\n"
            "🌙 Evening: ${evening.isEmpty ? 'N/A' : evening}\n\n"
            "Confidence: $confidencePercent%",
        routine: rec, // keeps the structured lists so the bubble can offer "Save"
      );
    }
  }

  Future<void> _saveRoutine(ChatMessage message) async {
    final rec = message.routine;
    if (rec == null || message.isSaving || message.isSaved) return;

    setState(() => message.isSaving = true);

    try {
      await SavedRoutineStorage.saveRoutine(
        morningSteps: List<String>.from(rec['morning_routine'] ?? []),
        eveningSteps: List<String>.from(rec['evening_routine'] ?? []),
        note: rec['note'] as String?,
      );

      if (mounted) {
        setState(() => message.isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine saved! You can log it from the Routine tab.')),
        );
      }
    } catch (e) {
      debugPrint('Save routine error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the routine. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => message.isSaving = false);
    }
  }

  Widget _buildBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFBCC2B6) : const Color(0xFFF0F2ED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text),
            if (message.routine != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (message.isSaved || message.isSaving)
                      ? null
                      : () => _saveRoutine(message),
                  icon: message.isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(message.isSaved ? Icons.check : Icons.bookmark_border, size: 18),
                  label: Text(message.isSaved ? 'Saved' : 'Save this routine'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A5A3A),
                    side: const BorderSide(color: Color(0xFF4A5A3A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Column(
          children: const [
            Text('Glow', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Skincare assistance', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildBubble(_messages[index]),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Glow is thinking…', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      filled: true,
                      fillColor: const Color(0xFFF0F2ED),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF4A5A3A),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}