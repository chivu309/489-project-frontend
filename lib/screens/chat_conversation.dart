import 'package:flutter/material.dart';
import '../services/api_service.dart';

// A simple data model for one chat bubble
class ChatMessage {
  final String text;
  final bool isUser; // true = right-aligned user bubble, false = bot bubble
  ChatMessage({required this.text, required this.isUser});
}

// Tracks which question we're currently asking, in order
enum ChatStep {
  concern,
  ageGroup,
  pregnant,
  healthConcern,
  done,
}

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  ChatStep _currentStep = ChatStep.concern;
  bool _isLoading = false;

  // Collected answers — filled in as the user taps quick-reply options
  String? _mainConcern;
  String? _ageGroup;
  bool? _isPregnant;
  bool? _hasHealthConcern;

  @override
  void initState() {
    super.initState();
    // Bot's opening message, shown as soon as the screen loads
    _addBotMessage("Ki ora, I'm Glow!\nTell me what's going on with your skin today?");
  }

  void _addBotMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    _scrollToBottom();
  }

  // Scrolls the chat list down so the newest message is visible
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

  // Called whenever the user taps a quick-reply option.
  // Advances the conversation to the next step.
  void _handleReply(String selectedLabel, {bool? boolValue}) {
    _addUserMessage(selectedLabel);

    switch (_currentStep) {
      case ChatStep.concern:
        _mainConcern = selectedLabel;
        setState(() => _currentStep = ChatStep.ageGroup);
        _addBotMessage("Thanks for sharing! What's your age group?");
        break;

      case ChatStep.ageGroup:
        _ageGroup = selectedLabel;
        setState(() => _currentStep = ChatStep.pregnant);
        _addBotMessage("Got it. Are you currently pregnant?");
        break;

      case ChatStep.pregnant:
        _isPregnant = boolValue;
        setState(() => _currentStep = ChatStep.healthConcern);
        _addBotMessage("Do you have any other health concerns?");
        break;

      case ChatStep.healthConcern:
        _hasHealthConcern = boolValue;
        setState(() => _currentStep = ChatStep.done);
        _addBotMessage("Thanks! Let me work out a recommendation for you...");
        _submitToBackend();
        break;

      case ChatStep.done:
        break; // conversation already finished, ignore further taps
    }
  }

  Future<void> _submitToBackend() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.submitSkinCheck(
        isPregnant: _isPregnant!,
        hasHealthConcern: _hasHealthConcern!,
        ageGroup: _ageGroup!,
        mainConcern: _mainConcern!,
      );

      // For now, just show the raw placeholder recommendation as a bot message.
      // Later this becomes the real formatted recommendation text.
      _addBotMessage("Recommendation: ${result['recommendation']}");
    } catch (e) {
      _addBotMessage("Sorry, something went wrong: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Returns the quick-reply options relevant to the CURRENT step
  List<Widget> _buildQuickReplies() {
    switch (_currentStep) {
      case ChatStep.concern:
        return [
          _replyButton('I have acne/breakout'),
          _replyButton('My skin is very dry'),
          _replyButton('I have redness/irritation'),
          _replyButton('Something else'),
        ];

      case ChatStep.ageGroup:
        return [
          _replyButton('20-30'),
          _replyButton('31-40'),
          _replyButton('41-50'),
          _replyButton('51-60'),
        ];

      case ChatStep.pregnant:
        return [
          _replyButton('Yes', boolValue: true),
          _replyButton('No', boolValue: false),
        ];

      case ChatStep.healthConcern:
        return [
          _replyButton('Yes', boolValue: true),
          _replyButton('No', boolValue: false),
        ];

      case ChatStep.done:
        return []; // no more questions once finished
    }
  }

  Widget _replyButton(String label, {bool? boolValue}) {
    return OutlinedButton(
      onPressed: () => _handleReply(label, boolValue: boolValue),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
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
            Text('Skincare assistance',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? const Color(0xFFBCC2B6)
                          : const Color(0xFFF0F2ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),

          // Loading spinner while waiting for the backend
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),

          // Quick-reply buttons for the current step
          if (!_isLoading && _currentStep != ChatStep.done)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _buildQuickReplies(),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}