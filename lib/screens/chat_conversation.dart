import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
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

  void _addBotMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: false)));
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

  // Builds the conversation history in the shape the backend expects
  List<Map<String, String>> _buildHistory() {
    return _messages
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    final historyBeforeThisTurn = _buildHistory(); // snapshot BEFORE adding new message
    _addUserMessage(text);
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendChatMessage(
        conversationHistory: historyBeforeThisTurn,
        latestMessage: text,
      ).timeout(const Duration(seconds: 20));

      debugPrint('RAW BACKEND RESPONSE: $result');

      _addBotMessage(result['reply'] ?? "Let's continue...");

      if (result['ready_to_assess'] == true && result['assessment'] != null) {
        final assessment = result['assessment'] as Map<String, dynamic>;
        _showAssessmentResult(assessment);
        // Conversation intentionally stays open — user can keep chatting
      }
    } catch (e) {
      _addBotMessage("Sorry, something went wrong: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssessmentResult(Map<String, dynamic> assessment) {
    final status = assessment['status'];

    if (status == 'escalated') {
      _addBotMessage("⚠️ ${assessment['message']}\n\nPlease consult a professional for further guidance.");
    } else if (status == 'follow_up_needed') {
      _addBotMessage(assessment['message'] ?? 'Could you share a bit more detail?');
    } else if (status == 'recommendation') {
      final rec = assessment['recommendation'] as Map<String, dynamic>?;
      if (rec == null) {
        _addBotMessage("Sorry, no recommendation data was returned.");
        return;
      }
      final morning = ((rec['morning_routine'] as List?) ?? []).join(', ');
      final evening = ((rec['evening_routine'] as List?) ?? []).join(', ');
      final confidenceValue = assessment['confidence'];
      final confidencePercent = confidenceValue != null ? ((confidenceValue as num) * 100).round() : 0;

      _addBotMessage(
          "🌞 Morning: ${morning.isEmpty ? 'N/A' : morning}\n\n"
              "🌙 Evening: ${evening.isEmpty ? 'N/A' : evening}\n\n"
              "Confidence: $confidencePercent%"
      );
    }
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
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: message.isUser ? const Color(0xFFBCC2B6) : const Color(0xFFF0F2ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
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