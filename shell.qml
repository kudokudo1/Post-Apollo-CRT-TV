import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        id: sideWindow

        title: "Post-Apollo Side"
        visible: true

        implicitWidth: 260
        implicitHeight: 900

        color: "#0D0212"

        SidePanel {
            anchors.fill: parent
        }
    }

    FloatingWindow {
        id: deckWindow

        title: "Post-Apollo Deck"
        visible: true

        implicitWidth: 1200
        implicitHeight: 220

        color: "#0D0212"

        ReceiverDeck {
            anchors.fill: parent
        }
    }
}
