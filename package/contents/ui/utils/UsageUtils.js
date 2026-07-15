.pragma library

const weeklyDurationSeconds = 10080 * 60
const dailyDurationSeconds = 24 * 60 * 60
const dailyAllowance = 100 / 7

function percentValue(value) {
    return Number(value).toLocaleString(Qt.locale(), "f", 1)
}

function percent(value) {
    return percentValue(value) + "%"
}

function dailyPace(remaining, resetAt, nowSeconds) {
    if (resetAt <= 0 || remaining < 0) return null

    const windowStartedAt = resetAt - weeklyDurationSeconds
    const effectiveNow = nowSeconds > 0 ? nowSeconds : Date.now() / 1000
    const elapsed = Math.max(0, Math.min(
        weeklyDurationSeconds,
        effectiveNow - windowStartedAt
    ))
    const currentDay = Math.min(
        7,
        Math.floor(elapsed / dailyDurationSeconds) + 1
    )
    return {
        actualRemaining: Math.max(0, Math.min(100, remaining)),
        todayRemaining: Math.max(0, 100 - currentDay * dailyAllowance),
        thresholdAt: Math.min(
            resetAt,
            windowStartedAt + currentDay * dailyDurationSeconds
        ),
        nextDayRemaining: Math.max(
            0,
            100 - Math.min(7, currentDay + 1) * dailyAllowance
        )
    }
}

function colorLevel(remaining, resetAt, nowSeconds) {
    const value = dailyPace(remaining, resetAt, nowSeconds)
    if (value === null) return 0
    if (value.actualRemaining >= value.todayRemaining) return 1
    if (value.actualRemaining >= value.nextDayRemaining) return 2
    return 3
}

function dailyRemainingThreshold(remaining, resetAt, nowSeconds) {
    const value = dailyPace(remaining, resetAt, nowSeconds)
    return value === null ? "" : percent(value.todayRemaining)
}

function dailyThresholdAt(remaining, resetAt, nowSeconds) {
    const value = dailyPace(remaining, resetAt, nowSeconds)
    return value === null ? 0 : value.thresholdAt
}

function panelReset(epochSeconds) {
    if (!epochSeconds) return "--.-- --:--"
    return Qt.formatDateTime(new Date(epochSeconds * 1000), "dd.MM HH:mm")
}

function reset(epochSeconds) {
    if (!epochSeconds) return ""
    return Qt.formatDateTime(new Date(epochSeconds * 1000), "ddd, dd.MM HH:mm")
}
