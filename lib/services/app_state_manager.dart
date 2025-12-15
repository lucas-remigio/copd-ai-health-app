import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/chat_message.dart';
import 'unified_step_service.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'package:flutter/foundation.dart';

/// Singleton class to manage global app state
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  // Services
  final UnifiedStepService _stepService = UnifiedStepService();
  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();

  // State
  bool _isInitialized = false;
  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  final List<ChatMessage> _chatHistory = [];
  int _stepGoal = 10000;

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

  /// Initialize all app services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ AppStateManager already initialized');
      return;
    }

    debugPrint('🚀 Initializing AppStateManager...');

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

    // Add welcome message to chat
    // if (_chatHistory.isEmpty) {
    //   _chatHistory.add(
    //     ChatMessage(
    //       text:
    //           'Olá! Sou o seu assistente de saúde. Pergunte-me sobre sugestões de caminhada, metas de passos ou locais próximos para explorar!',
    //       isUser: false,
    //       timestamp: DateTime.now(),
    //     ),
    //   );
    // }

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
  }

  /// Update a chat message at specific index
  void updateChatMessage(int index, ChatMessage message) {
    if (index >= 0 && index < _chatHistory.length) {
      _chatHistory[index] = message;
      _chatUpdateController.add(null);
    }
  }

  /// Set generating response state
  void setGeneratingResponse(bool isGenerating) {
    _isGeneratingResponse = isGenerating;
    _chatUpdateController.add(null);
  }

  /// Set step goal
  void setStepGoal(int goal) {
    if (goal > 0) {
      _stepGoal = goal;
      _stepGoalController.add(_stepGoal);
      debugPrint('🎯 Step goal updated to: $goal');
    }
  }

  /// Dispose all resources
  void dispose() {
    _stepService.dispose();
    _chatUpdateController.close();
    _stepGoalController.close();
    debugPrint('🗑️ AppStateManager disposed');
  }
}
