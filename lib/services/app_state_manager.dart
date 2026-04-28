import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../models/chat_message.dart';
import 'unified_step_service.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'chat_history_service.dart';
import 'package:flutter/foundation.dart';

/// Singleton class to manage global app state
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  // Keys for persistence
  static const String _stepGoalKey = 'step_goal';
  static const String _lastQuestionnaireKey = 'last_questionnaire_date';

  // Services
  final UnifiedStepService _stepService = UnifiedStepService();
  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();
  final ChatHistoryService _historyService = ChatHistoryService();
  late SharedPreferences _prefs;

  // State
  bool _isInitialized = false;
  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  final List<ChatMessage> _chatHistory = [];
  int _stepGoal = 10000;
  DateTime? _lastQuestionnaireDate;

  // Chat streaming state
  bool _isGeneratingResponse = false;
  final StreamController<void> _chatUpdateController =
      StreamController<void>.broadcast();
  final StreamController<int> _stepGoalController =
      StreamController<int>.broadcast();

  // Getters
  UnifiedStepService get stepService => _stepService;
  Position? get currentPosition => _currentPosition;
  List<Place> get nearbyPlaces => _nearbyPlaces;
  List<ChatMessage> get chatHistory => _chatHistory;
  bool get isInitialized => _isInitialized;
  bool get hasLocation => _currentPosition != null;
  bool get isGeneratingResponse => _isGeneratingResponse;
  Stream<void> get chatUpdateStream => _chatUpdateController.stream;
  int get stepGoal => _stepGoal;
  Stream<int> get stepGoalStream => _stepGoalController.stream;
  DateTime? get lastQuestionnaireDate => _lastQuestionnaireDate;

  /// Initialize all app services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ AppStateManager already initialized');
      return;
    }

    debugPrint('🚀 Initializing AppStateManager...');

    // Initialize SharedPreferences
    try {
      _prefs = await SharedPreferences.getInstance();
      _stepGoal = _prefs.getInt(_stepGoalKey) ?? 10000;
      
      final lastDateStr = _prefs.getString(_lastQuestionnaireKey);
      if (lastDateStr != null) {
        _lastQuestionnaireDate = DateTime.tryParse(lastDateStr);
      }
      
      debugPrint('✅ SharedPreferences initialized. Loaded goal: $_stepGoal');
    } catch (e) {
      debugPrint('⚠️ SharedPreferences initialization failed: $e');
    }

    // Load chat history
    try {
      final history = await _historyService.loadHistory();
      if (history.isNotEmpty) {
        _chatHistory.addAll(history);
        debugPrint('✅ Loaded ${history.length} messages from local storage');
      } else {
        clearChatHistory(); // Set default welcome message
      }
    } catch (e) {
      debugPrint('⚠️ Chat history loading failed: $e');
      clearChatHistory();
    }

    // Initialize step service
    try {
      await _stepService.initialize();
      debugPrint('✅ Step service initialized');
    } catch (e) {
      debugPrint('⚠️ Step service initialization failed: $e');
    }

    // Initialize location
    try {
      await refreshLocation();
      debugPrint('✅ Location initialized');
    } catch (e) {
      debugPrint('⚠️ Location initialization failed: $e');
    }

    _isInitialized = true;
    debugPrint('✅ AppStateManager initialized');
  }

  /// Refresh current location
  Future<void> refreshLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
      debugPrint(
        '📍 Location updated: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
      );
    } catch (e) {
      debugPrint('❌ Failed to get location: $e');
      rethrow;
    }
  }

  /// Fetch nearby places
  Future<void> fetchNearbyPlaces() async {
    if (_currentPosition == null) {
      throw Exception('Location not available');
    }

    try {
      _nearbyPlaces = await _placesService.fetchNearbyPlaces(_currentPosition!);
      debugPrint('📍 Fetched ${_nearbyPlaces.length} nearby places');
    } catch (e) {
      debugPrint('❌ Failed to fetch places: $e');
      rethrow;
    }
  }

  /// Add message to chat history
  void addChatMessage(ChatMessage message) {
    _chatHistory.add(message);
    _chatUpdateController.add(null);
    _historyService.saveHistory(_chatHistory);
  }

  /// Clear chat history (keeps welcome message)
  void clearChatHistory() {
    _chatHistory.clear();
    _chatHistory.add(
      ChatMessage(
        text:
            'Olá! Sou o seu assistente de saúde. Pergunte-me sobre sugestões de caminhada, metas de passos ou locais próximos para explorar!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    _chatUpdateController.add(null);
    _historyService.saveHistory(_chatHistory);
  }

  /// Update a chat message at specific index
  void updateChatMessage(int index, ChatMessage message) {
    if (index >= 0 && index < _chatHistory.length) {
      _chatHistory[index] = message;
      _chatUpdateController.add(null);
    }
  }

  /// Finalize message and save
  void finalizeMessageUpdate() {
    _historyService.saveHistory(_chatHistory);
    _chatUpdateController.add(null);
  }

  /// Log a real AI interaction
  void logAIInteraction(ChatMessage input, ChatMessage output) {
    _historyService.logInteraction(input: input, output: output);
  }

  /// Set generating response state
  void setGeneratingResponse(bool isGenerating) {
    _isGeneratingResponse = isGenerating;
    if (!isGenerating) {
      finalizeMessageUpdate();
    }
    _chatUpdateController.add(null);
  }

  /// Set step goal
  Future<void> setStepGoal(int goal) async {
    if (goal > 0) {
      _stepGoal = goal;
      _stepGoalController.add(_stepGoal);
      debugPrint('🎯 Step goal updated to: $goal');

      // Persist goal
      try {
        await _prefs.setInt(_stepGoalKey, goal);
        debugPrint('💾 Step goal persisted: $goal');
      } catch (e) {
        debugPrint('⚠️ Failed to persist step goal: $e');
      }
    }
  }

  /// Mark questionnaire as completed today
  Future<void> markQuestionnaireCompleted() async {
    _lastQuestionnaireDate = DateTime.now();
    try {
      await _prefs.setString(_lastQuestionnaireKey, _lastQuestionnaireDate!.toIso8601String());
      debugPrint('📅 Questionnaire completion date saved: $_lastQuestionnaireDate');
      // Trigger a UI update to hide the chat tab
      _chatUpdateController.add(null);
    } catch (e) {
      debugPrint('⚠️ Failed to save questionnaire date: $e');
    }
  }

  /// Check if questionnaire is due (every 7 days)
  bool isQuestionnaireDue() {
    if (_lastQuestionnaireDate == null) return true;
    final difference = DateTime.now().difference(_lastQuestionnaireDate!);
    // Using 7 days as the threshold
    return difference.inDays >= 7;
  }

  /// Get the date when the questionnaire will be available again
  DateTime getNextQuestionnaireDate() {
    if (_lastQuestionnaireDate == null) return DateTime.now();
    return _lastQuestionnaireDate!.add(const Duration(days: 7));
  }

  /// Dispose all resources
  void dispose() {
    _stepService.dispose();
    _chatUpdateController.close();
    _stepGoalController.close();
    debugPrint('🗑️ AppStateManager disposed');
  }
}
