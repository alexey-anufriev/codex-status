import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "utils/CommandUtils.js" as CommandUtils

Item {
    id: page

    property alias cfg_codexPath: codexPathField.text
    property alias cfg_refreshIntervalSeconds: refreshSpinBox.value
    property string cfg_codexPathDefault: ""
    property int cfg_refreshIntervalSecondsDefault: 30
    property string title: ""
    property bool statusIsError: false
    property string statusText: ""
    readonly property alias discoveryLoading: discoveryJob.running
    readonly property url helperUrl: Qt.resolvedUrl("../tools/discover-codex.sh")
    readonly property string helperPath: CommandUtils.localPath(helperUrl)

    implicitWidth: form.implicitWidth
    implicitHeight: form.implicitHeight + Kirigami.Units.largeSpacing

    function rediscover() {
        if (discoveryLoading) return
        if (helperPath.length === 0) {
            statusIsError = true
            statusText = i18n("Unable to resolve the discovery helper path")
            return
        }

        statusIsError = false
        statusText = i18n("Looking for Codex CLI…")
        discoveryJob.run(CommandUtils.command(helperPath, [], Date.now()))
    }

    Component.onCompleted: {
        statusText = codexPathField.text.trim().length > 0
            ? i18n("Codex CLI path is configured")
            : i18n("Enter a path or select Rediscover, then apply the settings")
    }

    Kirigami.FormLayout {
        id: form

        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.largeSpacing
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.TextField {
            id: codexPathField

            Kirigami.FormData.label: i18n("Codex executable:")
            Layout.fillWidth: true
            placeholderText: i18n("Absolute path to codex")
            enabled: !page.discoveryLoading
        }

        RowLayout {
            Kirigami.FormData.label: ""

            QQC2.Button {
                text: i18n("Rediscover")
                icon.name: "view-refresh"
                enabled: !page.discoveryLoading
                onClicked: page.rediscover()
            }

            QQC2.BusyIndicator {
                running: page.discoveryLoading
                visible: running
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            visible: text.length > 0
            text: page.statusText
            color: page.statusIsError
                ? Kirigami.Theme.negativeTextColor
                : Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
        }

        QQC2.SpinBox {
            id: refreshSpinBox

            Kirigami.FormData.label: i18n("Refresh interval:")
            from: 30
            to: 3600
            stepSize: 30
            editable: true
            textFromValue: function(value) {
                return i18np("%1 second", "%1 seconds", value)
            }
            valueFromText: function(text) {
                const parsed = parseInt(text)
                return Number.isNaN(parsed) ? 30 : parsed
            }
        }
    }

    ExecutableJob {
        id: discoveryJob

        onSucceeded: function(payload) {
            codexPathField.text = String(payload.codexPath || "")
            page.statusIsError = false
            page.statusText = payload.message
                ? String(payload.message)
                : i18n("Codex CLI found. Apply the settings to save it")
        }
        onFailed: function(message) {
            page.statusIsError = true
            page.statusText = message
        }
    }
}
