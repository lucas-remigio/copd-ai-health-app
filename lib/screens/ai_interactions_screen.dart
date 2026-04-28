import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../services/chat_history_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AIInteractionsScreen extends StatefulWidget {
  const AIInteractionsScreen({super.key});

  @override
  State<AIInteractionsScreen> createState() => _AIInteractionsScreenState();
}

class _AIInteractionsScreenState extends State<AIInteractionsScreen> {
  final ChatHistoryService _historyService = ChatHistoryService();
  List<Map<String, dynamic>> _interactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final log = await _historyService.loadInteractionLog();
    if (mounted) {
      setState(() {
        _interactions = log.reversed.toList(); // Newest first
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _interactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _interactions.length,
                  itemBuilder: (context, index) {
                    final interaction = _interactions[index];
                    return _buildInteractionGroup(interaction);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Ainda não há interações reais com a IA',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '(Mensagens do questionário não são incluídas)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionGroup(Map<String, dynamic> interaction) {
    final input = ChatMessage.fromJson(interaction['input']);
    final output = ChatMessage.fromJson(interaction['output']);
    final timestamp = DateTime.parse(interaction['timestamp']);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Interação IA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          
          // Input section
          _buildMessageSection(input, isInput: true),
          
          const Divider(height: 1),
          
          // Output section
          _buildMessageSection(output, isInput: false),
        ],
      ),
    );
  }

  Widget _buildMessageSection(ChatMessage message, {required bool isInput}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInput ? Icons.login : Icons.smart_toy,
                size: 14,
                color: isInput ? Colors.blue : AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                isInput ? 'INPUT (Prompt)' : 'OUTPUT (Resposta)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isInput ? Colors.blue : AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isInput 
            ? Text(
                message.text,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              )
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
          if (message.metadata != null) ...[
            const SizedBox(height: 12),
            Text(
              'Contexto: ${message.metadata!.entries.map((e) => "${e.key}: ${e.value}").join(" | ")}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
