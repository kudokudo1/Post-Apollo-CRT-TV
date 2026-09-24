import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        title: "Post-Apollo Bezel Top"
        visible: true
        implicitWidth: 1200
        implicitHeight: 36
        color: "transparent"
        // FloatingWindow does not expose Qt.Window flags in Quickshell 0.2.1.
        // An empty input mask makes this visual chassis fully click-through.
        mask: Region { width: 0; height: 0 }

        TvBezel {
            anchors.fill: parent
            edge: "top"
        }
    }

    FloatingWindow {
        title: "Post-Apollo Bezel Left"
        visible: true
        implicitWidth: 36
        implicitHeight: 900
        color: "transparent"
        // FloatingWindow does not expose Qt.Window flags in Quickshell 0.2.1.
        // An empty input mask makes this visual chassis fully click-through.
        mask: Region { width: 0; height: 0 }

        TvBezel {
            anchors.fill: parent
            edge: "left"
        }
    }

    FloatingWindow {
        title: "Post-Apollo Bezel Right"
        visible: true
        implicitWidth: 36
        implicitHeight: 900
        color: "transparent"
        // FloatingWindow does not expose Qt.Window flags in Quickshell 0.2.1.
        // An empty input mask makes this visual chassis fully click-through.
        mask: Region { width: 0; height: 0 }

        TvBezel {
            anchors.fill: parent
            edge: "right"
        }
    }

    FloatingWindow {
        title: "Post-Apollo Bezel Bottom"
        visible: true
        implicitWidth: 1200
        implicitHeight: 36
        color: "transparent"
        // FloatingWindow does not expose Qt.Window flags in Quickshell 0.2.1.
        // An empty input mask makes this visual chassis fully click-through.
        mask: Region { width: 0; height: 0 }

        TvBezel {
            anchors.fill: parent
            edge: "bottom"
        }
    }
}
