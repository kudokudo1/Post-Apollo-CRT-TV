import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        title: "Post-Apollo Deck"
        visible: true

        implicitWidth: 1200
        implicitHeight: 220

        color: "#100315"

        ReceiverDeck {
            anchors.fill: parent
        }
    }
}
