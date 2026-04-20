# AI Model Testing - In-App Automated Testing

## Overview

This system allows you to automatically test the fine-tuned AI model directly on your mobile device and collect performance metrics for each test case.

## Files Created

### 1. **lib/models/test_case.dart**

- Defines `TestCase` model with input, expected keywords, validation rules
- Defines `TestResult` model to store test outcomes
- Contains 9 default test cases covering all 3 workflows

### 2. **lib/services/test_runner_service.dart**

- Runs tests sequentially using `AILlamaService`
- Validates responses using regex and keyword matching
- Collects `PerformanceMetrics` for each inference
- Provides summary statistics

### 3. **lib/screens/ai_test_screen.dart**

- Full UI screen to display tests and results
- Real-time progress indicator
- Expandable cards showing:
  - Input prompt
  - AI response
  - Validation issues
  - Performance metrics (TTFT, tokens/sec, battery drain)

## How to Use

### Access the Screen

1. Open the app
2. Navigate to **Steps Screen** (main screen)
3. Tap the **menu icon** (three dots) in top-right
4. Select **"AI Model Testing"** 🔬

### Run Tests

1. Tap the **"Run Tests"** floating button
2. Watch real-time progress (9 tests)
3. Each test takes ~5-15 seconds
4. Total runtime: ~2-4 minutes

### View Results

- **Status Card**: Shows total/passed/failed/average score
- **Result Cards**: Tap to expand and see:
  - ✅ Pass or ❌ Fail indicator
  - Score (e.g., 5/5 = 100%)
  - Full input and response
  - Validation issues (missing keywords, wrong calculations)
  - **Performance Metrics**: TTFT, total time, tokens, speed, battery drain

### Clear Results

- Tap the **trash icon** in top-right to reset

## Test Cases

### Workflow 1: Goal Achieved (4 tests)

- Tests confidence levels 3%, 6%, 9%, 5%
- Validates correct calculation (e.g., 5000 × 1.03 = 5150)
- Checks for "Nova meta: X passos" format

### Workflow 2: Goal Not Achieved - Health (2 tests)

- Tests health-related reasons (fever, breathlessness)
- Validates "manter" (maintain) recommendation
- Ensures NO "aumentar" (increase) or "reduzir" (reduce)

### Workflow 3: Goal Not Achieved - Other (3 tests)

- Tests non-health reasons (rain, work, travel)
- Validates supportive language
- Ensures goal maintenance

## Validation Rules

### For Achieved Goals:

1. Contains congratulations (parabéns) ✅
2. Shows calculation (×, \*, =) ✅
3. **CRITICAL**: Correct new goal (e.g., 5150 passos) ✅

### For Not Achieved:

1. Recommends "manter" (maintain) ✅
2. Supportive language (compreendo, natural) ✅
3. **CRITICAL**: Must NOT suggest "aumentar" or "reduzir" ❌

## Performance Metrics Collected

Each test automatically tracks:

- **Time to First Token (TTFT)**: Latency before first response
- **Total Generation Time**: Full inference time
- **Token Count**: Number of tokens generated
- **Tokens per Second**: Inference speed
- **Battery Drain**: Percentage consumed
- **Battery Drain Rate**: % per second

## Export Data

After running tests, you can:

1. Navigate to **Performance Metrics** screen (same menu)
2. Export all metrics to CSV/JSON
3. Analyze in Python/Excel for research paper

## Adding Custom Tests

Edit `lib/models/test_case.dart` → `getDefaultCases()`:

```dart
TestCase(
  name: 'Your Test Name',
  input: '[CONTEXTO: ...]\n\nUser message here',
  expectedKeywords: ['keyword1', 'keyword2'],
  mustNotContain: ['forbidden1'],
  mustCalculate: true, // for achieved goals
  expectedNewGoal: 5150, // exact number
),
```

## Tips

- **Battery**: Ensure device is charged (tests drain battery)
- **Time**: Each test takes 5-15 seconds, plan accordingly
- **Interruptions**: Don't interrupt tests mid-run
- **Model**: Ensure fine-tuned model is downloaded first
- **Results**: Scroll through cards to see all details

## Research Use

This tool is perfect for:

1. **Validation**: Ensure model behaves correctly
2. **Performance**: Collect latency/battery data
3. **Comparison**: Test different model versions
4. **Documentation**: Screenshot results for papers

## Troubleshooting

**Tests won't run?**

- Check model is initialized (Steps screen should load first)
- Ensure battery permission is granted

**All tests failing?**

- Fine-tuned model may not be loaded
- Check model file exists in app documents

**Metrics missing?**

- Performance tracking should be enabled (default: ON)
- Check Performance Metrics screen settings

## Example Output

```
Status: ✅ Tests completed!
Total: 9 | Passed: 8 | Failed: 1 | Score: 91.2%

Test: Goal Achieved - Low Confidence
✅ PASS - 5/5 (100%)
TTFT: 245ms | Total: 3520ms | Tokens: 42 | Speed: 11.9/s | Battery: 1%

Test: Not Achieved - Fever
❌ FAIL - 3/4 (75%)
Issues: Missing keyword: 'recuperação'
```

---

**Ready to test!** 🚀 Tap Run Tests and watch your AI model get validated in real-time.
