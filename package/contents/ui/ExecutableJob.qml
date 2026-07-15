import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: job

    readonly property bool running: activeSource.length > 0
    property string activeSource: ""

    signal succeeded(var payload)
    signal failed(string message)

    function reportFailure(message) {
        console.warn("Codex Status process failed:", message)
        failed(message)
    }

    function run(command) {
        if (running) return false
        activeSource = command
        executable.connectSource(command)
        return true
    }

    visible: false
    implicitWidth: 0
    implicitHeight: 0

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            job.activeSource = ""

            const stdout = String(data["stdout"] || "").trim()
            const stderr = String(data["stderr"] || "").trim()
            const exitCode = Number(
                data["exit code"] === undefined ? -1 : data["exit code"]
            )

            if (stdout.length === 0) {
                job.reportFailure(stderr.length > 0
                    ? stderr
                    : i18n("Process returned no output (exit code %1)", exitCode))
                return
            }

            try {
                const payload = JSON.parse(stdout)
                if (!payload || payload.ok !== true) {
                    job.reportFailure(payload && payload.error
                        ? String(payload.error)
                        : i18n("Invalid process response"))
                    return
                }
                job.succeeded(payload)
            } catch (error) {
                job.reportFailure(i18n("Unable to parse process output: %1", error))
            }
        }
    }
}
