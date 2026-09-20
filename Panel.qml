import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "bakugo.cliamp"

    property string trackTitle: ""
    property string trackArtist: ""
    property string station: ""
    property bool playing: false
    property bool loaded: false

    visible: root.loaded
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function refresh() {
        if (!statusProc.running) statusProc.running = true
    }

    function update(raw) {
        try {
            var data = JSON.parse(raw)
            if (data.ok && data.track) {
                root.trackTitle = data.track.title ?? ""
                root.trackArtist = data.track.artist ?? ""
                root.station = data.track.station ?? ""
                root.playing = data.state === "playing"
                root.loaded = true
            }
        } catch (err) { /* keep last known state */ }
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProc
        // cliamp exits nonzero when no daemon owns the socket (e.g. before TUI starts)
        command: ["bash", "-c", "cliamp status --json || true"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.update(text)
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.trackTitle = ""
                root.trackArtist = ""
                root.station = ""
                root.playing = false
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.playing ? "\u25B6" : "\u23F8"
        slotSize: Style.bar.statusSlot
        fontSize: Style.font.caption
        tooltipText: root.trackTitle + "\u2003\u2014\u2003" + root.trackArtist + "\u2003\u2022\u2003" + root.station
        onPressed: {
            // cliamp's "toggle" cycles playing→paused→stopped, so a second press
            // would kill the stream. Only use toggle while playing; use play to resume.
            Quickshell.execDetached(["cliamp", root.playing ? "toggle" : "play"])
        }
    }
}
