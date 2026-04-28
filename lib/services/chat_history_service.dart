import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message.dart';

class ChatHistoryService {
  static const String _fileName = 'chat_history.json';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<void> saveHistory(List<ChatMessage> history) async {
    try {
      final file = await _localFile;
      final String jsonString = jsonEncode(
        history.map((m) => m.toJson()).toList(),
      );
      await file.writeAsString(jsonString);
      debugPrint('💾 Chat history saved locally');
    } catch (e) {
      debugPrint('❌ Error saving chat history: $e');
    }
  }

  Future<List<ChatMessage>> loadHistory() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => ChatMessage.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
    }
    return [];
  }

  Future<void> clearHistory() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('❌ Error clearing chat history: $e');
    }
  }

  Future<void> logInteraction({
    required ChatMessage input,
    required ChatMessage output,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/ai_interactions_log.jsonl');
      
      final interaction = {
        'timestamp': DateTime.now().toIso8601String(),
        'input': input.toJson(),
        'output': output.toJson(),
      };
      
      await logFile.writeAsString('${jsonEncode(interaction)}\n', mode: FileMode.append);
      debugPrint('📝 Real AI interaction logged');
    } catch (e) {
      debugPrint('❌ Error logging interaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadInteractionLog() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/ai_interactions_log.jsonl');
      
      if (await logFile.exists()) {
        final lines = await logFile.readAsLines();
        return lines.map((line) => jsonDecode(line) as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading log: $e');
    }
    return [];
  }

  Future<File> getInteractionLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/ai_interactions_log.jsonl');
  }
}
