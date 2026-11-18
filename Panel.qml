import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "bakugo.cliamp"

  property var playback: null
  readonly property bool playing: playback?.state === "playing"
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string trackInfo: {
    const track = playback?.track
    const title = [track?.title, track?.artist].filter(Boolean).join(" — ")
    return [title, track?.station].filter(Boolean).join(" • ")
  }

  visible: playback !== null
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: statusProc
    command: ["cliamp", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          const status = JSON.parse(text)
          root.playback = status?.ok === true ? status : null
        } catch (error) {
          root.playback = null
        }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.playback = null
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    hasVisualContent: true
    labelVisible: false
    fixedWidth: vertical ? -1 : Style.bar.iconSlot
    fixedHeight: vertical ? Style.bar.iconSlot : -1
    tooltipText: (root.trackInfo || "CLIamp") + "\n" + (root.playing ? "Click to pause" : "Click to play")

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton)
        Quickshell.execDetached(["cliamp", root.playing ? "pause" : "play"])
    }

    BorderSurface {
      id: badge
      anchors.centerIn: parent
      width: Style.bar.iconSize
      height: width
      radius: width / 2
      scale: button.pressScale
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.playing ? 0.18 : 0.08)
      borderSpec: Border.flat(Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.58), 1)

      OpticalGlyph {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        anchors.horizontalCenterOffset: root.playing ? 1 : 0
        text: root.playing ? "\uf04b" : "\uf04c"
        fontFamily: button.fontFamily
        fontSize: Style.bar.iconFont
        paintedSize: Math.round(badge.width / 2)
        color: root.foreground
      }
    }
  }
}
