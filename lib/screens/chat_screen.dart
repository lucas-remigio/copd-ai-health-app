import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:copd_ai_health_app/services/ai_llama_service.dart';
import 'package:copd_ai_health_app/services/app_state_manager.dart';
import 'package:copd_ai_health_app/services/unified_step_service.dart';
import 'package:copd_ai_health_app/utils/step_goal_calculator.dart';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';

enum QuestionnaireState {
  askingWeeklyGoal,
  askingCurrentSteps,
  askingWhatHappened,
  askingConfidence,
  completed,
}

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
  StreamSubscription<int>? _stepCountSubscription;
  StreamSubscription<void>? _chatUpdateSubscription;

  int _stepCount = 0;
  String _currentStreamingText = '';

  // Questionnaire state
  QuestionnaireState _questionnaireState = QuestionnaireState.askingWeeklyGoal;
  int? _weeklyGoal;
  int? _currentWeekSteps;
  String? _whatHappened;
  int? _confidenceLevel;

  @override
  void initState() {
    super.initState();
    _initializeContext();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _chatUpdateSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    // Don't dispose singleton
    super.dispose();
  }

  Future<void> _initializeContext() async {
    // Get current step count and listen to changes
    _stepCount = _appState.stepService.currentStepCount;

    await _stepCountSubscription?.cancel();
    _stepCountSubscription = _appState.stepService.stepCountStream.listen((
      steps,
    ) {
      if (mounted) {
        setState(() => _stepCount = steps);
      }
    });

    // Listen to chat updates from the singleton
    await _chatUpdateSubscription?.cancel();
    _chatUpdateSubscription = _appState.chatUpdateStream.listen((_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });

    await _bootstrapQuestionnaire();
  }

  Future<void> _bootstrapQuestionnaire() async {
    if (_appState.stepService.activeMethod ==
        StepDetectionMethod.healthConnect) {
      final goal = _appState.stepGoal;
      _weeklyGoal = goal;

      _appState.addChatMessage(
        ChatMessage(
          text:
              'Usei automaticamente a tua meta atual da app: **$goal passos/dia**.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      var average =
          await _appState.stepService.getAverageDailyStepsFromHealthConnect(
            days: 7,
          ) ??
          0;

      if (!mounted) return;

      _currentWeekSteps = average;

      _appState.addChatMessage(
        ChatMessage(
          text:
              'Fui buscar ao Health Connect a tua média diária dos últimos 7 dias: **$average passos/dia**.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      final goalAchieved = average >= goal;
      if (!mounted) return;
      setState(() {
        _questionnaireState = goalAchieved
            ? QuestionnaireState.askingConfidence
            : QuestionnaireState.askingWhatHappened;
      });

      _showQuestionnaireQuestion();
      return;
    }

    // Fallback for non-Health Connect flows.
    _showQuestionnaireQuestion();
  }

  void _showQuestionnaireQuestion() {
    String question = '';
    switch (_questionnaireState) {
      case QuestionnaireState.askingWeeklyGoal:
        question = 'Qual é a tua meta semanal de passos por dia?';
        break;
      case QuestionnaireState.askingCurrentSteps:
        question = 'Quantos passos deste em média esta semana?';
        break;
      case QuestionnaireState.askingWhatHappened:
        question = 'O que aconteceu esta semana?';
        break;
      case QuestionnaireState.askingConfidence:
        question =
            'Numa escala de 1 a 10, qual é a tua confiança para aumentar a meta de passos?';
        break;
      case QuestionnaireState.completed:
        return;
    }

    _appState.addChatMessage(
      ChatMessage(text: question, isUser: false, timestamp: DateTime.now()),
    );
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

    // Handle questionnaire flow
    if (_questionnaireState != QuestionnaireState.completed) {
      _handleQuestionnaireResponse(text);
      return;
    }

    // Regular chat flow
    _appState.setGeneratingResponse(true);
    _currentStreamingText = '';

    try {
      // Add empty AI message that will be filled with streaming text
      final aiMessageIndex = _appState.chatHistory.length;
      _appState.addChatMessage(
        ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );

      await widget.aiService.sendMessage(
        text,
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
          text: 'Desculpe, ocorreu um erro: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _appState.setGeneratingResponse(false);
    }
  }

  void _handleQuestionnaireResponse(String response) {
    switch (_questionnaireState) {
      case QuestionnaireState.askingWeeklyGoal:
        final goal = int.tryParse(response);
        if (goal == null || goal <= 0) {
          _appState.addChatMessage(
            ChatMessage(
              text: 'Por favor, insere um número válido de passos.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          return;
        }
        setState(() {
          _weeklyGoal = goal;
          _questionnaireState = QuestionnaireState.askingCurrentSteps;
        });
        _showQuestionnaireQuestion();
        break;

      case QuestionnaireState.askingCurrentSteps:
        final steps = int.tryParse(response);
        if (steps == null || steps < 0) {
          _appState.addChatMessage(
            ChatMessage(
              text: 'Por favor, insere um número válido de passos.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          return;
        }
        final goalAchieved = steps >= _weeklyGoal!;
        setState(() {
          _currentWeekSteps = steps;
          // If goal not achieved, ask what happened. Otherwise ask confidence.
          _questionnaireState = goalAchieved
              ? QuestionnaireState.askingConfidence
              : QuestionnaireState.askingWhatHappened;
        });
        _showQuestionnaireQuestion();
        break;

      case QuestionnaireState.askingWhatHappened:
        if (response.trim().isEmpty) {
          _appState.addChatMessage(
            ChatMessage(
              text: 'Por favor, conta-me o que aconteceu.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          return;
        }
        setState(() {
          _whatHappened = response;
          _questionnaireState = QuestionnaireState.completed;
        });
        _sendContextualMessage();
        break;

      case QuestionnaireState.askingConfidence:
        final confidence = int.tryParse(response);
        if (confidence == null || confidence < 1 || confidence > 10) {
          _appState.addChatMessage(
            ChatMessage(
              text: 'Por favor, insere um número entre 1 e 10.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          return;
        }

        final newGoal = StepGoalCalculator.calculateNewGoal(
          _weeklyGoal!,
          confidence,
        );
        _appState.setStepGoal(newGoal);

        setState(() {
          _confidenceLevel = confidence;
          _questionnaireState = QuestionnaireState.completed;
        });
        _sendContextualMessage();
        break;

      case QuestionnaireState.completed:
        break;
    }
  }

  Future<void> _sendContextualMessage() async {
    final goalAchieved = _currentWeekSteps! >= _weeklyGoal!;
    debugPrint(
      '📊 Sending contextual message. Goal achieved: $goalAchieved, Confidence level: $_confidenceLevel, Current Steps: $_currentWeekSteps, Weekly Goal: $_weeklyGoal',
    );

    String contextMessage;
    if (goalAchieved) {
      // Goal achieved - include confidence
      contextMessage =
          '[CONTEXTO: Meta semanal: $_weeklyGoal passos/dia. '
          'Meta atingida: Sim (média de $_currentWeekSteps passos). '
          'Confiança para aumentar: $_confidenceLevel/10.]\n\n'
          'Consegui a meta esta semana e '
          'sinto-me $_confidenceLevel em 10 de confiança para aumentar.';
    } else {
      // Goal not achieved - include what happened
      contextMessage =
          '[CONTEXTO: Meta semanal: $_weeklyGoal passos/dia. '
          'Meta atingida: Não (média de $_currentWeekSteps passos).]\n\n'
          'Não consegui a meta porque $_whatHappened';
    }

    _appState.setGeneratingResponse(true);
    _currentStreamingText = '';

    try {
      // Add empty AI message that will be filled with streaming text
      final aiMessageIndex = _appState.chatHistory.length;
      _appState.addChatMessage(
        ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );

      await widget.aiService.sendDirectMessage(
        contextMessage,
        onToken: (token) {
          _currentStreamingText += token;
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

      if (goalAchieved && _confidenceLevel != null) {
        final newGoal = StepGoalCalculator.calculateNewGoal(
          _weeklyGoal!,
          _confidenceLevel!,
        );
        _appState.addChatMessage(
          ChatMessage(
            text:
                'A tua nova meta de passos foi atualizada para $newGoal passos/dia.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }

      _appState.setGeneratingResponse(false);
    } catch (e) {
      _appState.addChatMessage(
        ChatMessage(
          text: 'Desculpe, ocorreu um erro: $e',
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
        title: const Text('Chat de Saúde'),
        actions: [
          if (_appState.chatHistory.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _appState.isGeneratingResponse
                  ? null
                  : () {
                      setState(() {
                        _appState.clearChatHistory();
                        _questionnaireState =
                            QuestionnaireState.askingWeeklyGoal;
                        _weeklyGoal = null;
                        _currentWeekSteps = null;
                        _whatHappened = null;
                        _confidenceLevel = null;
                      });
                      _bootstrapQuestionnaire();
                    },
              tooltip: 'Reiniciar questionário',
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
                    decoration: InputDecoration(
                      hintText:
                          _questionnaireState != QuestionnaireState.completed
                          ? 'Escreve a tua resposta...'
                          : 'Escreve a tua mensagem...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_appState.isGeneratingResponse,
                    keyboardType:
                        _questionnaireState ==
                                QuestionnaireState.askingWeeklyGoal ||
                            _questionnaireState ==
                                QuestionnaireState.askingCurrentSteps ||
                            _questionnaireState ==
                                QuestionnaireState.askingConfidence
                        ? TextInputType.number
                        : TextInputType.text,
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
    // Should not reach here as we show first question in initState
    return const SizedBox.shrink();
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
                color: AppTheme.secondary.withValues(alpha: 0.1),
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
              child: message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        em: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textPrimary,
                        ),
                        listBullet: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade200,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
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
