pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "utils/UsageUtils.js" as Usage

RowLayout {
    id: row

    required property int remaining
    required property int resetAt
    required property int fetchedAt
    readonly property string dailyThreshold: Usage.dailyRemainingThreshold(
        remaining,
        resetAt,
        fetchedAt
    )

    function limitColor() {
        switch (Usage.colorLevel(remaining, resetAt, fetchedAt)) {
        case 1: return Kirigami.Theme.positiveTextColor
        case 2: return Kirigami.Theme.neutralTextColor
        case 3: return Kirigami.Theme.negativeTextColor
        default: return Kirigami.Theme.textColor
        }
    }

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: "W -"
        color: Kirigami.Theme.textColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
    }

    PlasmaComponents.Label {
        Layout.minimumWidth: 0
        text: Usage.percent(row.remaining)
        color: row.limitColor()
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    PlasmaComponents.Label {
        visible: row.dailyThreshold.length > 0
        text: "of"
        color: Kirigami.Theme.textColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
    }

    PlasmaComponents.Label {
        visible: row.dailyThreshold.length > 0
        text: row.dailyThreshold
        color: Kirigami.Theme.positiveTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: "↻ " + Usage.panelReset(row.resetAt)
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }
}
