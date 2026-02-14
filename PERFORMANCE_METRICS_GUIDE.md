# Performance Metrics Collection Guide for Research Paper

## Overview

This guide explains how to collect and analyze **inference latency** and **battery consumption** metrics from your on-device AI health app to strengthen your research paper.

---

## 📊 Metrics Tracked

### ⚡ Latency Metrics

1. **Time to First Token (TTFT)**: Time from prompt submission to first token generation
   - Critical for perceived responsiveness
   - Target: < 200ms for good UX

2. **Average Token Latency**: Average time per token generation
   - Indicates model efficiency
   - Measured in ms/token

3. **Total Generation Time**: Complete inference duration
   - From start to completion
   - Measured in milliseconds

4. **Tokens per Second**: Generation throughput
   - Higher is better
   - Industry standard metric

### 🔋 Battery Metrics

1. **Battery Level Before/After**: Percentage at start and end of inference

2. **Battery Drain**: Total percentage consumed during inference

3. **Battery Drain Rate**: Percentage per second
   - Normalized metric for comparison
   - Target: < 0.02%/sec (< 5% per 15min session)

---

## 🔧 Setup Instructions

### 1. Install Dependencies

The required packages are already added to `pubspec.yaml`:

- `battery_plus: ^6.0.3` - Battery monitoring
- `share_plus: ^10.2.0` - Data export

Run:

```bash
flutter pub get
```

### 2. Initialize Metrics Service

The service is automatically initialized when you use `AILlamaService`. The metrics are tracked for:

- Test responses
- Fitness context messages (with step data)
- Questionnaire responses

### 3. Access Metrics UI

Add a route to the Performance Metrics screen in your app navigation:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PerformanceMetricsScreen(),
  ),
);
```

Or add it as a settings option in your existing screens.

---

## 📱 Data Collection Protocol

### For Research Papers - Recommended Approach:

#### **Phase 1: Baseline Collection (50-100 inferences)**

1. **Controlled Environment**:
   - Full battery charge (90-100%)
   - Airplane mode (no network interference)
   - Same ambient temperature
   - Close all background apps

2. **Test Scenarios**:
   - Short prompts (< 50 tokens): 20 tests
   - Medium prompts (50-150 tokens): 30 tests
   - Long prompts (> 150 tokens): 20 tests
   - Questionnaire flow: 10 complete sessions

3. **Record Conditions**:
   - Device model (e.g., "Samsung Galaxy S23")
   - Android version
   - Battery health (Settings → Battery)
   - CPU/GPU temperature (use CPU-Z app)

#### **Phase 2: Real-World Usage (7-14 days)**

1. Enable metrics tracking
2. Use app naturally
3. Export data weekly
4. Compare with baseline

---

## 📤 Exporting Data

### Via UI (Easiest)

1. Open Performance Metrics screen
2. Tap menu (⋮) → "Export to CSV" or "Export to JSON"
3. Files saved to: `/data/user/0/com.example.health_test_app/app_flutter/`
4. Use "Share" to send via email/cloud

### Via ADB (Direct access)

```bash
# Connect device via USB
adb devices

# Pull CSV file
adb pull /sdcard/Android/data/com.example.health_test_app/files/performance_metrics*.csv .

# Pull JSON file
adb pull /sdcard/Android/data/com.example.health_test_app/files/performance_metrics*.json .
```

### Programmatic Export

```dart
final metricsService = PerformanceMetricsService();
final csvFile = await metricsService.exportToCSV();
final jsonFile = await metricsService.exportToJSON();
```

---

## 📈 Data Analysis

### Using Python/Pandas

```python
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load data
df = pd.read_csv('performance_metrics_2026-02-14.csv')

# Basic statistics
print("=== LATENCY STATS ===")
print(f"Avg TTFT: {df['time_to_first_token_ms'].mean():.2f}ms ± {df['time_to_first_token_ms'].std():.2f}ms")
print(f"Median TTFT: {df['time_to_first_token_ms'].median():.2f}ms")
print(f"95th percentile TTFT: {df['time_to_first_token_ms'].quantile(0.95):.2f}ms")

print(f"\nAvg Token Latency: {df['average_token_latency_ms'].mean():.2f}ms")
print(f"Avg Speed: {df['tokens_per_second'].mean():.2f} tokens/sec")

print("\n=== BATTERY STATS ===")
print(f"Avg Drain per Inference: {df['battery_drain_percent'].mean():.3f}%")
print(f"Avg Drain Rate: {df['battery_drain_rate_percent_per_sec'].mean():.6f}%/sec")

# Estimate battery impact for clinical usage
avg_session_time = 15 * 60  # 15 minutes in seconds
avg_drain_rate = df['battery_drain_rate_percent_per_sec'].mean()
estimated_drain_15min = avg_drain_rate * avg_session_time
print(f"\nProjected battery drain for 15min session: {estimated_drain_15min:.2f}%")

# Plot distributions
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

# TTFT distribution
axes[0, 0].hist(df['time_to_first_token_ms'], bins=30, edgecolor='black')
axes[0, 0].axvline(200, color='red', linestyle='--', label='Target: 200ms')
axes[0, 0].set_xlabel('Time to First Token (ms)')
axes[0, 0].set_ylabel('Frequency')
axes[0, 0].set_title('TTFT Distribution')
axes[0, 0].legend()

# Token generation speed
axes[0, 1].scatter(df['token_count'], df['tokens_per_second'], alpha=0.5)
axes[0, 1].set_xlabel('Token Count')
axes[0, 1].set_ylabel('Tokens/Second')
axes[0, 1].set_title('Generation Speed vs Output Length')

# Battery drain
axes[1, 0].hist(df['battery_drain_percent'], bins=30, edgecolor='black', color='orange')
axes[1, 0].set_xlabel('Battery Drain per Inference (%)')
axes[1, 0].set_ylabel('Frequency')
axes[1, 0].set_title('Battery Drain Distribution')

# Total generation time vs battery drain
axes[1, 1].scatter(df['total_generation_time_ms']/1000, df['battery_drain_percent'], alpha=0.5)
axes[1, 1].set_xlabel('Generation Time (seconds)')
axes[1, 1].set_ylabel('Battery Drain (%)')
axes[1, 1].set_title('Battery Drain vs Generation Time')

plt.tight_layout()
plt.savefig('performance_analysis.png', dpi=300)
plt.show()

# Export summary for paper
summary = {
    'ttft_mean_ms': df['time_to_first_token_ms'].mean(),
    'ttft_std_ms': df['time_to_first_token_ms'].std(),
    'ttft_p95_ms': df['time_to_first_token_ms'].quantile(0.95),
    'token_latency_mean_ms': df['average_token_latency_ms'].mean(),
    'speed_mean_tps': df['tokens_per_second'].mean(),
    'speed_std_tps': df['tokens_per_second'].std(),
    'battery_drain_mean_pct': df['battery_drain_percent'].mean(),
    'battery_drain_std_pct': df['battery_drain_percent'].std(),
    'battery_15min_projection_pct': estimated_drain_15min,
    'total_inferences': len(df),
}

pd.DataFrame([summary]).to_csv('performance_summary_for_paper.csv', index=False)
print("\n✅ Summary exported to 'performance_summary_for_paper.csv'")
```

### Statistical Tests

```python
# Compare different message types
from scipy import stats

questionnaire = df[df['message_type'] == 'questionnaire']
fitness_context = df[df['message_type'] == 'fitness_context']

# T-test for TTFT difference
t_stat, p_value = stats.ttest_ind(
    questionnaire['time_to_first_token_ms'],
    fitness_context['time_to_first_token_ms']
)

print(f"\nTTFT difference between message types:")
print(f"t-statistic: {t_stat:.4f}, p-value: {p_value:.4f}")

# Effect size (Cohen's d)
pooled_std = np.sqrt(
    (questionnaire['time_to_first_token_ms'].std()**2 +
     fitness_context['time_to_first_token_ms'].std()**2) / 2
)
cohens_d = (questionnaire['time_to_first_token_ms'].mean() -
            fitness_context['time_to_first_token_ms'].mean()) / pooled_std
print(f"Effect size (Cohen's d): {cohens_d:.4f}")
```

---

## 📝 Reporting in Your Paper

### Example Methods Section:

> **Performance Evaluation**: We measured inference latency and battery consumption using the `battery_plus` Flutter plugin on a [Device Model] running Android [Version]. Metrics were collected across N inferences under controlled conditions. Time to First Token (TTFT), average token latency, and generation speed were recorded for each inference. Battery drain was measured at 1% precision using the Android Battery Manager API.

### Example Results Section:

> **On-Device Inference Performance**: The [Model Name] (768MB) achieved a mean TTFT of X.X ± Y.Y ms across N inferences, with 95% of responses starting within Z ms. Average generation speed was A.A ± B.B tokens/second. Battery consumption averaged C.C% per inference, projecting to approximately D.D% drain per 15-minute usage session—well within clinical usability thresholds.

### Example Table:

| Metric             | Mean ± SD       | Median | 95th Percentile |
| ------------------ | --------------- | ------ | --------------- |
| TTFT (ms)          | 150 ± 45        | 140    | 235             |
| Token Latency (ms) | 75 ± 15         | 73     | 98              |
| Speed (tokens/sec) | 13.3 ± 2.1      | 13.5   | 16.2            |
| Battery Drain (%)  | 0.08 ± 0.03     | 0.07   | 0.13            |
| Drain Rate (%/sec) | 0.0012 ± 0.0005 | 0.0011 | 0.0019          |

**Table 1**: On-device AI inference performance metrics collected from N=100 inferences on [Device Model].

---

## 🎯 Key Points for Top-Tier Papers

1. **Reproducibility**: Document exact device specs, Android version, model quantization
2. **Statistical Rigor**: Report mean, SD, median, and 95th percentile
3. **Clinical Context**: Compare to user acceptability thresholds (TTFT < 200ms, < 5% battery per session)
4. **Comparison**: If possible, benchmark against cloud-based alternatives (show latency/privacy tradeoffs)
5. **Ablation Study**: Compare different model sizes (e.g., 768MB vs 2.6GB model)

### Suggested Visualizations:

- **Box plots**: TTFT and battery drain distributions
- **Scatter plot**: Generation time vs battery consumption (show linear relationship)
- **CDF plot**: Cumulative distribution of TTFT (highlight < 200ms threshold)
- **Bar chart**: Compare metrics across different prompt types

---

## 🔬 Advanced: Thermal Throttling Analysis

For even more comprehensive analysis:

```dart
// Optional: Add CPU temperature tracking if available
// Requires device-specific plugins or native code
```

Or manually monitor with external tools:

- **CPU-Z** (Android app) - Monitor temps during testing
- **Android Developer Options** → "Suppress GPU overdraw" to reduce heat

---

## 🚀 Next Steps

1. **Collect baseline data**: 50-100 controlled inferences
2. **Real-world testing**: 7-14 days of actual use
3. **Export and analyze**: Use Python scripts above
4. **Create visualizations**: Publication-ready figures
5. **Write-up**: Include in Methods and Results sections

---

## 📧 Questions?

For citation or methodology questions, document:

- Flutter version: `flutter --version`
- Plugin versions: Check `pubspec.lock`
- Device specifications: Model, Android version, RAM, chipset

This detailed metrics collection will significantly strengthen your paper's technical contribution and make it suitable for top-tier AI healthcare conferences (e.g., AAAI, NeurIPS, MLHC).

---

**Generated by Health Test App Performance Metrics System**  
_Last Updated: February 14, 2026_
