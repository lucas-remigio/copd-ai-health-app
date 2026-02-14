# Performance Metrics Implementation - Quick Start

## ✅ What We've Added

### 1. **Performance Metrics Service** (`lib/services/performance_metrics_service.dart`)

- Automatically tracks inference latency (TTFT, token speed, total time)
- Monitors battery consumption during AI inference
- Stores metrics persistently
- Supports CSV and JSON export

### 2. **Performance Metrics Model** (`lib/models/performance_metrics.dart`)

- Data structure for metrics
- Statistical calculations (mean, std, percentiles)
- Human-readable summaries

### 3. **AI Service Integration** (`lib/services/ai_llama_service.dart`)

- Automatic tracking in all AI operations:
  - `getTestResponse()` → tracks as 'test'
  - `sendMessage()` → tracks as 'fitness_context'
  - `sendDirectMessage()` → tracks as 'questionnaire'
- Zero code changes needed for existing functionality

### 4. **Metrics Visualization UI** (`lib/screens/performance_metrics_screen.dart`)

- View real-time statistics
- Export to CSV/JSON
- Share summaries
- Clear data

### 5. **Comprehensive Guide** (`PERFORMANCE_METRICS_GUIDE.md`)

- Data collection protocol
- Python analysis scripts
- How to report in papers
- Publication-ready examples

---

## 🚀 How to Use

### Step 1: Install Dependencies

```bash
flutter pub get
```

### Step 2: Run the App

The metrics service initializes automatically on app startup.

### Step 3: Generate Some Data

- Use the chat feature
- Complete the questionnaire
- Have conversations with the AI

### Step 4: View Metrics

1. Open the app
2. Go to Steps screen
3. Tap menu (⋮) → "Performance Metrics"

### Step 5: Export Data

From the Performance Metrics screen:

- Tap menu → "Export to CSV" (for Excel/Python)
- Tap menu → "Export to JSON" (for programmatic analysis)
- Or tap "Share Stats" to share a summary

---

## 📊 What Gets Tracked

Every AI inference automatically records:

| Metric            | Description         | Target               |
| ----------------- | ------------------- | -------------------- |
| **TTFT**          | Time to first token | < 200ms              |
| **Token Latency** | ms per token        | Lower is better      |
| **Speed**         | Tokens per second   | > 5 tok/sec          |
| **Battery Drain** | % consumed          | < 0.1% per inference |
| **Battery Rate**  | %/second            | < 0.02%/sec          |

---

## 🔬 For Your Paper

### Quick Analysis (Python)

```python
import pandas as pd

# Load exported data
df = pd.read_csv('performance_metrics_2026-02-14.csv')

# Key statistics
print(f"Avg TTFT: {df['time_to_first_token_ms'].mean():.0f}ms")
print(f"Avg Speed: {df['tokens_per_second'].mean():.2f} tokens/sec")
print(f"Avg Battery: {df['battery_drain_percent'].mean():.3f}%")

# For 15-minute session projection
drain_rate = df['battery_drain_rate_percent_per_sec'].mean()
print(f"15-min battery drain: {drain_rate * 15 * 60:.2f}%")
```

### Example Results Section

> Our on-device implementation achieved a mean TTFT of **X ms** (SD=Y), with 95% of inferences starting within **Z ms**. Average generation speed was **A tokens/second**. Battery consumption averaged **B%** per inference, projecting to **C%** drain per 15-minute session—well within clinical usability thresholds.

---

## 🎯 Next Steps

1. **Collect Baseline Data** (50-100 inferences)
   - Various prompt lengths
   - Different scenarios
   - Controlled environment

2. **Real-World Testing** (7-14 days)
   - Normal app usage
   - Track automatically

3. **Export & Analyze**
   - Use provided Python scripts
   - Create visualizations

4. **Report in Paper**
   - Follow examples in guide
   - Include statistical rigor

---

## 📁 Files Changed

- ✅ `lib/models/performance_metrics.dart` (NEW)
- ✅ `lib/services/performance_metrics_service.dart` (NEW)
- ✅ `lib/screens/performance_metrics_screen.dart` (NEW)
- ✅ `lib/services/ai_llama_service.dart` (MODIFIED - added tracking)
- ✅ `lib/screens/loading_screen.dart` (MODIFIED - initialize service)
- ✅ `lib/screens/steps_screen.dart` (MODIFIED - added menu item)
- ✅ `pubspec.yaml` (MODIFIED - added battery_plus, share_plus)
- ✅ `PERFORMANCE_METRICS_GUIDE.md` (NEW - comprehensive documentation)

---

## 🆘 Troubleshooting

### Battery permissions on Android

If battery metrics show 0%:

1. Go to Android Settings → Battery
2. Enable battery usage tracking for the app

### Export not working

Files are saved to app documents directory. Use ADB to pull:

```bash
adb pull /sdcard/Android/data/com.example.health_test_app/files/ .
```

### Metrics not appearing

Check debug logs for initialization:

```
📊 Performance Metrics Service initialized
```

---

## 💡 Tips for Best Results

1. **Controlled Testing**:
   - Full battery (90%+)
   - Airplane mode
   - Close background apps
   - Same device/conditions

2. **Statistical Validity**:
   - Collect ≥ 50 samples per condition
   - Report mean ± SD
   - Include percentiles (P95)

3. **Paper Quality**:
   - Compare to cloud alternatives
   - Show latency/privacy tradeoff
   - Test multiple model sizes

---

**You're all set!** 🎉

Your app now automatically tracks performance metrics suitable for **top-tier AI healthcare papers** (NeurIPS, AAAI, MLHC).

For detailed analysis instructions, see **`PERFORMANCE_METRICS_GUIDE.md`**.
