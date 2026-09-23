import Quickshell
import QtQuick

ShellRoot {
    FloatingWindow {
        title: "Post-Apollo Side"
        visible: true

        implicitWidth: 260
        implicitHeight: 900

        color: "#100315"

        SidePanel {
            anchors.fill: parent
        }
    }
}
