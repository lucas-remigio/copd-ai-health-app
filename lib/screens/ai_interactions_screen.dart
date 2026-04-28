import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
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
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export_json') {
                _exportJSON();
              } else if (value == 'clear') {
                _confirmClear();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_json',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar JSONL'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text('Limpar Tudo', style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
            ],
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
      floatingActionButton: _interactions.isEmpty 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _shareFullHistory,
              icon: const Icon(Icons.share),
              label: const Text('Partilhar Tudo'),
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
                Text(
                  'Interação IA • $dateStr',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () => _copyInteraction(input, output, dateStr),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      tooltip: 'Copiar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 16),
                      onPressed: () => _shareInteraction(input, output, dateStr),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      tooltip: 'Partilhar',
                    ),
                  ],
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

  String _formatInteraction(ChatMessage input, ChatMessage output, String date) {
    String text = '🤖 INTERAÇÃO IA ($date)\n';
    text += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    text += '📥 INPUT:\n${input.text}\n\n';
    if (input.metadata != null) {
      text += '📝 CONTEXTO:\n${input.metadata!.entries.map((e) => "${e.key}: ${e.value}").join("\n")}\n\n';
    }
    text += '📤 OUTPUT:\n${output.text}\n';
    text += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    return text;
  }

  void _copyInteraction(ChatMessage input, ChatMessage output, String date) {
    final text = _formatInteraction(input, output, date);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interação copiada para a área de transferência')),
    );
  }

  void _shareInteraction(ChatMessage input, ChatMessage output, String date) {
    final text = _formatInteraction(input, output, date);
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareFullHistory() async {
    final logFile = await _historyService.getInteractionLogFile();
    if (await logFile.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(logFile.path)],
          text: 'Histórico de Interações COPD AI Health',
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum log encontrado para partilhar')),
        );
      }
    }
  }

  Future<void> _exportJSON() async {
    final logFile = await _historyService.getInteractionLogFile();
    if (await logFile.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(logFile.path)],
          subject: 'AI_Interactions_Export.jsonl',
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum log para exportar')),
        );
      }
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico?'),
        content: const Text(
          'Isto irá apagar permanentemente o log de interações com a IA. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final logFile = await _historyService.getInteractionLogFile();
      if (await logFile.exists()) {
        await logFile.delete();
      }
      _loadLog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Histórico de interações limpo')),
        );
      }
    }
  }
}
