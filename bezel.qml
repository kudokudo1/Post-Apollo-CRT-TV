import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        title: "Post-Apollo Bezel Top"
        visible: true
        implicitWidth: 1200
        implicitHeight: 36
        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

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
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

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
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

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
        flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

        TvBezel {
            anchors.fill: parent
            edge: "bottom"
        }
    }
}
