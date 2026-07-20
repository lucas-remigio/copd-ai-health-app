/// Decides, from a thermal-headroom reading, whether on-device inference should
/// pause to cool before the next measured test.
///
/// Headroom is an absolute 0.0 (cool) .. 1.0 (at the throttling threshold)
/// signal, so — unlike a throughput-based approach — no baseline calibration is
/// needed. Gating on headroom *before* each test means a throttled inference is
/// never recorded, which keeps TTFT and tokens/sec comparable across a long run.
/// It is also independent of the metrics being reported, which avoids the
/// circularity of using tokens/sec to gate tokens/sec.
///
/// The two thresholds form a hysteresis band so the run does not flap on and off
/// around a single cutoff: cool down once headroom reaches [runCeiling], and only
/// resume once it falls back to [resumeFloor].
///
/// Pure decision logic (no timers, no platform calls) so it can be unit-tested;
/// the caller owns the actual polling and sleeping.
class ThermalGovernor {
  ThermalGovernor({this.runCeiling = 0.7, this.resumeFloor = 0.5})
    : assert(runCeiling > 0),
      assert(resumeFloor > 0 && resumeFloor <= runCeiling);

  /// Cool down before the next test once headroom reaches this level.
  final double runCeiling;

  /// Resume measuring once headroom has dropped back to this level.
  final double resumeFloor;

  /// True when the device is hot enough that the next test should wait.
  /// An unusable reading (NaN/negative) is treated as "don't block" so a missing
  /// signal never stalls the run.
  bool shouldCoolDown(double headroom) {
    if (!_isUsable(headroom)) return false;
    return headroom >= runCeiling;
  }

  /// True when the device has cooled enough to resume measuring. An unusable
  /// reading counts as recovered so a cooldown loop can never get stuck.
  bool hasRecovered(double headroom) {
    if (!_isUsable(headroom)) return true;
    return headroom <= resumeFloor;
  }

  bool _isUsable(double headroom) => headroom.isFinite && headroom >= 0;
}
