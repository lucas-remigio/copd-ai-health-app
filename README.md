# AlentoAI: On-Device LLM for COPD Pulmonary Rehabilitation

**AlentoAI** is a privacy-first mobile health application developed for a Master's degree thesis. It serves as a specialized digital companion designed to motivate patients with Chronic Obstructive Pulmonary Disease (COPD/DPOC) to increase their physical activity through personalized, on-device artificial intelligence.

## 🎯 Clinical Vision
Traditional pulmonary rehabilitation often suffers from low adherence. AlentoAI bridges this gap by providing a 24/7 assistant that:
*   **Calculates Adaptive Goals:** Uses a fine-tuned model to analyze the previous week's performance and calculate the optimal step count objective for the next week.
*   **Provides Contextual Motivation:** Suggests safe walking routes (parks, cafes) based on real-time location and current patient capacity.
*   **Ensures Clinical Safety:** Recognizes symptoms like dyspnea and fatigue, offering immediate breathing techniques (e.g., pursed-lip breathing) rather than pushing for more activity.

## 🧠 The AlentoAI Engine
At the heart of the application is **AlentoAI**, a local Large Language Model (LLM) optimized for healthcare privacy and mobile performance.

*   **Base Model:** Google Gemma-3-1b.
*   **Inference:** 100% On-Device via `llama.cpp` (GGUF Q4_K_M quantization).
*   **Privacy:** No health data or conversation history ever leaves the device, ensuring full GDPR compliance for sensitive medical information.
*   **Fine-tuning:** Specialized for Portuguese (PT-PT) medical context, focusing on step-count mathematics, motivational psychology, and COPD symptom management.

## 📱 Key Features
*   **Smart Activity Tracking:** Automatic step counting via Android HealthConnect and internal pedometer services.
*   **Location-Aware Suggestions:** Integrates Google Maps/Places API to convert nearby destinations into "step distances" (e.g., "The park is 1,200 steps away, perfect for your goal").
*   **Research Metrics Suite:** Built-in tools to track **Time to First Token (TTFT)**, tokens/sec, and **battery drain**, providing empirical data for the thesis results section.
*   **Automated Validation:** A dedicated AI Testing screen to verify the model's clinical logic against predefined workflows.

## 🛠 Technical Stack
*   **Framework:** Flutter (Dart)
*   **AI Engine:** `llama_flutter_android`
*   **Maps:** Google Maps Flutter + Geolocation
*   **State Management:** Reactive streams for real-time step and AI response updates.

## 🚀 Setup & Installation

### Prerequisites
*   Flutter SDK (^3.8.1)
*   Android Studio / Xcode (for mobile deployment)
*   Google Maps API Key

### Quick Start
If you recently renamed the project directory or encounter build errors:
```bash
# Clean stale paths and fetch dependencies
flutter clean
flutter pub get

# Run the application
flutter run
```

### Model Configuration
1.  Upload your fine-tuned `gemma-3-1b-alento.gguf` in HuggingFace and update the `modelPath` in `lib/services/ai_llama_service.dart` to point to your model's URL or local asset path.
2.  Add your Google Maps API Key to the `.env` file.

---
*Developed by Lucas Remígio as part of a Master's Degree investigation into Edge AI and Hybrid Pulmonary Rehabilitation.*
