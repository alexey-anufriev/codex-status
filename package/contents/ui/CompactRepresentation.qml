pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

MouseArea {
    id: compactRoot

    required property bool loading
    required property string errorText
    required property bool weeklyAvailable
    required property int weeklyRemaining
    required property int weeklyResetAt
    required property int lastFetchedAt

    signal refreshRequested()

    readonly property int padding: Math.max(
        2,
        Math.round(Kirigami.Units.smallSpacing / 2)
    )
    readonly property int iconSize: Math.max(
        24,
        Math.round(Kirigami.Units.iconSizes.small * 1.6)
    )

    Layout.minimumWidth: 100
    Layout.preferredWidth: Math.max(100, content.implicitWidth + padding * 2)
    Layout.fillHeight: true
    implicitWidth: Layout.preferredWidth
    implicitHeight: Math.max(
        content.implicitHeight + padding * 2,
        Kirigami.Units.iconSizes.small
    )
    clip: true
    hoverEnabled: true
    onClicked: refreshRequested()

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: compactRoot.padding
        spacing: Kirigami.Units.smallSpacing

        Item {
            Layout.preferredWidth: compactRoot.iconSize
            Layout.preferredHeight: compactRoot.iconSize
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.fill: parent
                source: Qt.resolvedUrl("codex.svg")
                opacity: compactRoot.loading ? 0.25 : 1

                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
            }

            PlasmaComponents.BusyIndicator {
                anchors.fill: parent
                running: compactRoot.loading
                visible: running
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            WeeklyLimitRow {
                Layout.fillWidth: true
                visible: compactRoot.weeklyAvailable
                    && compactRoot.errorText.length === 0
                remaining: compactRoot.weeklyRemaining
                resetAt: compactRoot.weeklyResetAt
                fetchedAt: compactRoot.lastFetchedAt
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: compactRoot.errorText.length > 0
                    || !compactRoot.weeklyAvailable
                text: compactRoot.errorText.length > 0
                    ? i18n("Codex !")
                    : (compactRoot.loading ? i18n("Codex …") : i18n("No limit data"))
                color: compactRoot.errorText.length > 0
                    ? Kirigami.Theme.negativeTextColor
                    : Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: Font.DemiBold
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
    }
}
