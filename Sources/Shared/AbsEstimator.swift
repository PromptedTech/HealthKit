import Foundation

// MARK: - ETA result

enum ETAState: Equatable {
    case needMoreData          // < 4 data points
    case notLosingYet          // trend slope ≥ 0 (not in a deficit)
    case alreadyThere          // current BF% ≤ target
    case onTrack(date: Date, weeks: Double)
}

struct AbsETA: Equatable {
    let state: ETAState
    let currentBodyFat: Double    // percent, e.g. 22.0
    let targetBodyFat: Double
    let dailyDropPercent: Double  // rate, negative when losing; 0 otherwise
    let weeklyRateKg: Double      // weight loss kg/week (negative = losing); 0 if unknown
}

// MARK: - Pure estimation functions

enum AbsEstimator {

    // MARK: - Main entry

    /// Compute an Abs ETA from a body-fat series and optional weight series.
    /// All inputs are raw HealthKit samples (oldest first).
    static func estimate(
        bodyFatSeries: [(date: Date, pct: Double)],
        weightSeries: [(date: Date, kg: Double)] = [],
        targetBodyFat: Double,
        heightCm: Double = 0,
        age: Int = 0,
        isMale: Bool = true
    ) -> AbsETA {
        // Prefer real BF% data; fall back to Deurenberg estimate from weight
        let bfSeries: [(date: Date, pct: Double)]
        if bodyFatSeries.count >= 2 {
            bfSeries = bodyFatSeries
        } else if weightSeries.count >= 2 && heightCm > 0 && age > 0 {
            bfSeries = weightSeries.map { point in
                let bmi = point.kg / pow(heightCm / 100.0, 2)
                let estimated = 1.20 * bmi + 0.23 * Double(age) - 10.8 * (isMale ? 1 : 0) - 5.4
                return (point.date, max(3, min(60, estimated)))
            }
        } else {
            let current = bodyFatSeries.last?.pct ?? weightSeries.last.map { w -> Double in
                let bmi = heightCm > 0 ? w.kg / pow(heightCm / 100, 2) : 0
                return bmi > 0 ? 1.20 * bmi + 0.23 * Double(age) - 10.8 * (isMale ? 1 : 0) - 5.4 : 0
            } ?? 0
            return AbsETA(state: .needMoreData, currentBodyFat: current,
                          targetBodyFat: targetBodyFat, dailyDropPercent: 0, weeklyRateKg: 0)
        }

        guard bfSeries.count >= 4 else {
            return AbsETA(state: .needMoreData, currentBodyFat: bfSeries.last?.pct ?? 0,
                          targetBodyFat: targetBodyFat, dailyDropPercent: 0, weeklyRateKg: 0)
        }

        let currentBF = bfSeries.last!.pct

        if currentBF <= targetBodyFat {
            return AbsETA(state: .alreadyThere, currentBodyFat: currentBF,
                          targetBodyFat: targetBodyFat, dailyDropPercent: 0, weeklyRateKg: 0)
        }

        let slope = linearSlope(series: bfSeries)  // percent per day

        guard slope < 0 else {
            let weeklyKg = weightSeries.count >= 4 ? linearSlope(series: weightSeries) * 7 : 0
            return AbsETA(state: .notLosingYet, currentBodyFat: currentBF,
                          targetBodyFat: targetBodyFat, dailyDropPercent: slope, weeklyRateKg: weeklyKg)
        }

        let daysNeeded = (currentBF - targetBodyFat) / abs(slope)
        let etaDate = Calendar.current.date(byAdding: .day, value: Int(daysNeeded.rounded()), to: Date())!
        let weeksNeeded = daysNeeded / 7

        let weeklyKg = weightSeries.count >= 4 ? linearSlope(series: weightSeries) * 7 : 0

        return AbsETA(
            state: .onTrack(date: etaDate, weeks: weeksNeeded),
            currentBodyFat: currentBF,
            targetBodyFat: targetBodyFat,
            dailyDropPercent: slope,
            weeklyRateKg: weeklyKg
        )
    }

    // MARK: - Default targets

    static func defaultTargetBodyFat(isMale: Bool) -> Double {
        isMale ? 12.0 : 20.0
    }

    // MARK: - Linear regression

    /// Ordinary least-squares slope (value-per-day) over a dated series.
    static func linearSlope(series: [(date: Date, pct: Double)]) -> Double {
        guard series.count >= 2 else { return 0 }
        let xs = series.map { $0.date.timeIntervalSince(series[0].date) / 86400.0 }
        let ys = series.map { $0.pct }
        return slope(xs: xs, ys: ys)
    }

    static func linearSlope(series: [(date: Date, kg: Double)]) -> Double {
        guard series.count >= 2 else { return 0 }
        let xs = series.map { $0.date.timeIntervalSince(series[0].date) / 86400.0 }
        let ys = series.map { $0.kg }
        return slope(xs: xs, ys: ys)
    }

    private static func slope(xs: [Double], ys: [Double]) -> Double {
        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumX2 - sumX * sumX
        guard abs(denom) > 1e-9 else { return 0 }
        return (n * sumXY - sumX * sumY) / denom
    }
}
