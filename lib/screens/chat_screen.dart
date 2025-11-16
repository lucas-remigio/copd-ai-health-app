import 'package:flutter/material.dart';
import 'package:health_test_app/services/ai_llama_service.dart';
import 'package:health_test_app/services/app_state_manager.dart';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final AILlamaService aiService;

  const ChatScreen({super.key, required this.aiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _appState = AppStateManager();

  int _stepCount = 0;
  String _currentStreamingText = '';

  @override
  void initState() {
    super.initState();
    _initializeContext();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Don't dispose singleton
    super.dispose();
  }

  void _initializeContext() {
    // Get current step count and listen to changes
    _stepCount = _appState.stepService.currentStepCount;

    _appState.stepService.stepCountStream.listen((steps) {
      if (mounted) {
        setState(() => _stepCount = steps);
      }
    });

    // Listen to chat updates from the singleton
    _appState.chatUpdateStream.listen((_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _appState.isGeneratingResponse) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messageController.clear();
    _appState.addChatMessage(userMessage);
    _appState.setGeneratingResponse(true);
    _currentStreamingText = '';

    try {
      // Add empty AI message that will be filled with streaming text
      final aiMessageIndex = _appState.chatHistory.length;
      _appState.addChatMessage(
        ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );

      await widget.aiService.getHealthRecommendation(
        _stepCount,
        _appState.stepGoal,
        _appState.nearbyPlaces,
        onToken: (token) {
          _currentStreamingText += token;
          // Update the AI message with streamed text
          _appState.updateChatMessage(
            aiMessageIndex,
            ChatMessage(
              text: _currentStreamingText,
              isUser: false,
              timestamp: _appState.chatHistory[aiMessageIndex].timestamp,
            ),
          );
        },
      );

      _appState.setGeneratingResponse(false);
    } catch (e) {
      _appState.addChatMessage(
        ChatMessage(
          text: 'Sorry, I encountered an error: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _appState.setGeneratingResponse(false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Chat'),
        actions: [
          if (_appState.chatHistory.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _appState.isGeneratingResponse
                  ? null
                  : () {
                      _appState.clearChatHistory();
                    },
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _appState.chatHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _appState.chatHistory.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_appState.chatHistory[index]);
                    },
                  ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about walking suggestions...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_appState.isGeneratingResponse,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _appState.isGeneratingResponse
                      ? null
                      : _sendMessage,
                  mini: true,
                  child: _appState.isGeneratingResponse
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start a Conversation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask me about walking recommendations,\nstep goals, or places to visit',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 20,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primary
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser ? Colors.white : AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
