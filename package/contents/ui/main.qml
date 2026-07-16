pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "utils/CommandUtils.js" as CommandUtils
import "utils/UsageUtils.js" as Usage

PlasmoidItem {
    id: root

    property bool loading: false
    property string errorText: ""
    property int weeklyRemaining: -1
    property bool weeklyWindowAvailable: false
    property int weeklyResetAt: 0
    property int resetCreditCount: -1
    property var resetCreditDetails: []
    property int lastFetchedAt: 0

    readonly property url helperUrl: Qt.resolvedUrl("../tools/codex-status.sh")
    readonly property string helperPath: CommandUtils.localPath(helperUrl)

    preferredRepresentation: compactRepresentation
    toolTipTextFormat: Text.RichText
    toolTipMainText: i18n(
        "Codex usage limits v%1",
        root.plasmoid.metaData.version
    )
    toolTipSubText: tooltipText()

    function resetText(epochSeconds) {
        const value = Usage.reset(epochSeconds)
        return value.length > 0 ? value : i18n("unknown")
    }

    function htmlText(value) {
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
            .replace(/'/g, "&#39;")
    }

    function expirationColor(expiresAt) {
        if (expiresAt <= 0) return ""

        const secondsRemaining = expiresAt - lastFetchedAt
        if (secondsRemaining < 24 * 60 * 60) {
            return String(Kirigami.Theme.negativeTextColor)
        }
        if (secondsRemaining <= 2 * 24 * 60 * 60) {
            return String(Kirigami.Theme.neutralTextColor)
        }
        return ""
    }

    function tooltipLine(value, color) {
        const text = htmlText(value)
        return color.length > 0
            ? "<span style=\"color: " + color + "\">" + text + "</span>"
            : text
    }

    function tooltipText() {
        if (errorText.length > 0) return tooltipLine(errorText, "")
        if (!weeklyWindowAvailable && resetCreditCount < 0) {
            return tooltipLine(
                loading ? i18n("Refreshing…") : i18n("No data yet"),
                ""
            )
        }

        let lines = []
        if (weeklyWindowAvailable) {
            const dailyThreshold = Usage.dailyRemainingThreshold(
                weeklyRemaining,
                weeklyResetAt,
                lastFetchedAt
            )
            const dailyThresholdAt = Usage.dailyThresholdAt(
                weeklyRemaining,
                weeklyResetAt,
                lastFetchedAt
            )
            lines.push(tooltipLine(i18n(
                "Weekly remaining: %1% until %2",
                Usage.percentValue(weeklyRemaining),
                resetText(weeklyResetAt)
            ), ""))
            if (dailyThreshold.length > 0 && dailyThresholdAt > 0) {
                lines.push(tooltipLine(i18n(
                    "Daily threshold: %1 by %2",
                    dailyThreshold,
                    resetText(dailyThresholdAt)
                ), ""))
            }
        }

        if (resetCreditCount >= 0) {
            lines.push("")
            lines.push(tooltipLine(i18np(
                "%1 reset credit available",
                "%1 reset credits available",
                resetCreditCount
            ), ""))
            for (let index = 0; index < resetCreditDetails.length; index++) {
                const credit = resetCreditDetails[index]
                const title = credit.title && credit.title.length > 0
                    ? credit.title
                    : i18n("Reset credit %1", index + 1)
                const expiration = credit.expiresAt > 0
                    ? i18n("expires %1", resetText(credit.expiresAt))
                    : i18n("does not expire")
                lines.push(tooltipLine(
                    i18n("• %1 — %2", title, expiration),
                    expirationColor(credit.expiresAt)
                ))
            }
            lines.push("")
        }

        lines.push(tooltipLine(
            i18n("Updated: %1", resetText(lastFetchedAt)),
            ""
        ))
        return lines.join("<br>")
    }

    function refresh() {
        if (loading) return

        const codexPath = String(root.plasmoid.configuration.codexPath || "").trim()
        if (helperPath.length === 0) {
            errorText = i18n("Unable to resolve the bundled helper path")
            return
        }
        if (codexPath.length === 0) {
            errorText = i18n(
                "Codex CLI is not configured. Open the widget settings and select Rediscover"
            )
            return
        }

        loading = true
        errorText = ""
        helperJob.run(CommandUtils.command(helperPath, [codexPath], Date.now()))
    }

    function applyPayload(payload) {
        weeklyWindowAvailable = payload.weeklyWindow !== null
            && payload.weeklyWindow !== undefined
        weeklyRemaining = weeklyWindowAvailable
            ? Number(payload.weeklyWindow.remainingPercent)
            : -1
        weeklyResetAt = weeklyWindowAvailable && payload.weeklyWindow.resetsAt
            ? Number(payload.weeklyWindow.resetsAt)
            : 0
        const resetCredits = payload.rateLimitResetCredits
        resetCreditCount = resetCredits
            && resetCredits.availableCount !== undefined
            ? Number(resetCredits.availableCount)
            : -1
        resetCreditDetails = resetCredits && Array.isArray(resetCredits.credits)
            ? resetCredits.credits
            : []
        lastFetchedAt = payload.fetchedAt
            ? Number(payload.fetchedAt)
            : Math.floor(Date.now() / 1000)
        errorText = ""
    }

    compactRepresentation: CompactRepresentation {
        loading: root.loading
        errorText: root.errorText
        weeklyAvailable: root.weeklyWindowAvailable
        weeklyRemaining: root.weeklyRemaining
        weeklyResetAt: root.weeklyResetAt
        lastFetchedAt: root.lastFetchedAt
        onRefreshRequested: root.refresh()
    }

    // Required by PlasmoidItem even though clicks refresh instead of opening a popup.
    fullRepresentation: Item {
        implicitWidth: 1
        implicitHeight: 1
    }

    ExecutableJob {
        id: helperJob

        onSucceeded: function(payload) {
            root.loading = false
            root.applyPayload(payload)
        }
        onFailed: function(message) {
            root.loading = false
            root.errorText = message
        }
    }

    Timer {
        interval: Math.max(
            30,
            Number(root.plasmoid.configuration.refreshIntervalSeconds || 30)
        ) * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
