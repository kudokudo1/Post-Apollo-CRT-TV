import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    // Darker chassis
    color: "#100315"

    property color dock: "#14041C"
    property color dockInner: "#09010D"

    property color cyan: "#55CFCA"
    property color cyanDim: "#1E6D6A"
    property color orange: "#ED981A"
    property color offwhite: "#DCF3FA"

    property color plastic: "#19171F"
    property color plasticEdge: "#3D3746"

    property string pixelFont: "GohuFont 11 Nerd Font Mono"

    // ========================================================
    // CHANNEL DIAL
    // ========================================================

    component ChannelDial: Item {
        id: dialRoot

        required property string title
        required property var labels
        required property int selectedIndex

        width: 154
        height: 136

        function angleForIndex(i, count) {
            return -90 + (360 / count) * i;
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            text: dialRoot.title
            color: root.offwhite

            font {
                family: root.pixelFont
                pixelSize: 9
                bold: true
            }
        }

        Rectangle {
            id: dialDock

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16

            width: 118
            height: 116

            color: root.dock

            border {
                width: 1
                color: root.cyan
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6

                color: root.dockInner

                border {
                    width: 1
                    color: root.orange
                }
            }

            Item {
                anchors.centerIn: parent

                width: 94
                height: 94

                // OUTER MECHANICAL RING
                Rectangle {
                    anchors.centerIn: parent

                    width: 94
                    height: 94
                    radius: 47

                    color: "#060108"

                    border {
                        width: 2
                        color: "#332238"
                    }
                }

                // RAISED DIAL BODY
                Rectangle {
                    id: dialBody

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1

                    width: 84
                    height: 84
                    radius: 42

                    color: root.plastic

                    border {
                        width: 1
                        color: root.plasticEdge
                    }

                    layer.enabled: true

                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowOpacity: 0.75
                        shadowBlur: 0.3
                        shadowVerticalOffset: 4
                    }

                    // CYAN NUMBER DIVIDER
                    Rectangle {
                        anchors.centerIn: parent

                        width: 68
                        height: 68
                        radius: 34

                        color: "transparent"

                        border {
                            width: 2
                            color: root.cyan
                        }
                    }

                    // PRINTED CHANNEL NUMBERS
                    Repeater {
                        model: dialRoot.labels.length

                        Text {
                            required property int index

                            text: dialRoot.labels[index]

                            color: index === dialRoot.selectedIndex ? root.orange : root.cyan

                            font {
                                family: root.pixelFont
                                pixelSize: 7
                                bold: index === dialRoot.selectedIndex
                            }

                            property real a: (Math.PI * 2 * index / dialRoot.labels.length) - Math.PI / 2

                            property real r: 27

                            x: dialBody.width / 2 + Math.cos(a) * r - width / 2

                            y: dialBody.height / 2 + Math.sin(a) * r - height / 2
                        }
                    }

                    // FULL-DIAMETER HANDLE
                    Item {
                        anchors.centerIn: parent

                        width: 68
                        height: 6

                        transformOrigin: Item.Center

                        rotation: dialRoot.angleForIndex(dialRoot.selectedIndex, dialRoot.labels.length)

                        Rectangle {
                            x: 2
                            y: 1

                            width: 64
                            height: 4

                            // Flat machined ends
                            radius: 0

                            color: root.offwhite
                        }

                        // Orange marker is INSIDE the handle.
                        // A white tip remains beyond it.
                        Rectangle {
                            x: 57
                            y: 1

                            width: 5
                            height: 4

                            radius: 0

                            color: root.orange
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent

                        width: 10
                        height: 10
                        radius: 5

                        color: root.offwhite

                        border {
                            width: 1
                            color: "#A0B2B7"
                        }
                    }
                }
            }
        }
    }

    // ========================================================
    // SLIDER
    // ========================================================

    component TuningSlider: Item {
        id: sliderRoot

        required property string leftArrow
        required property string rightArrow

        width: 154
        height: 54

        Rectangle {
            anchors.centerIn: parent

            width: 144
            height: 40

            color: root.dock

            border {
                width: 1
                color: root.cyan
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5

                color: root.dockInner

                border {
                    width: 1
                    color: root.orange
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 5

                    text: sliderRoot.leftArrow
                    color: root.offwhite

                    font {
                        family: root.pixelFont
                        pixelSize: 14
                        bold: true
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 5

                    text: sliderRoot.rightArrow
                    color: root.offwhite

                    font {
                        family: root.pixelFont
                        pixelSize: 14
                        bold: true
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter

                        leftMargin: 25
                        rightMargin: 25
                    }

                    height: 11
                    radius: 3

                    color: "#050109"

                    border {
                        width: 1
                        color: "#21152A"
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter

                            leftMargin: 3
                            rightMargin: 3
                        }

                        height: 2
                        color: root.cyanDim
                    }

                    Rectangle {
                        anchors.centerIn: parent

                        width: 16
                        height: 27
                        radius: 2

                        color: root.offwhite

                        border {
                            width: 1
                            color: "#889A9F"
                        }

                        layer.enabled: true

                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowOpacity: 0.65
                            shadowBlur: 0.2
                            shadowVerticalOffset: 3
                        }

                        Rectangle {
                            anchors.centerIn: parent

                            width: 2
                            height: 18

                            color: root.orange
                        }
                    }
                }
            }
        }
    }

    // Screen-side seam
    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        width: 2
        color: root.cyan
    }

    // ========================================================
    // UPPER CONTROL DOCK
    // Whole assembly lowered a tiny amount.
    // ========================================================

    Rectangle {
        id: controlDock

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            leftMargin: 10
            rightMargin: 10
            topMargin: 10
        }

        height: 404

        color: root.dock

        border {
            width: 1
            color: root.cyan
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 6

            color: root.dockInner

            border {
                width: 1
                color: root.orange
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            // tiny drop
            anchors.topMargin: 16

            width: 154
            spacing: 0

            ChannelDial {
                title: "SESSION"

                labels: ["12", "01", "02", "03", "04", "09", "10", "11"]

                selectedIndex: 3
            }

            ChannelDial {
                title: "TAB"

                labels: ["06", "01", "02", "03", "04", "05"]

                selectedIndex: 2
            }

            TuningSlider {
                leftArrow: "▲"
                rightArrow: "▼"
            }

            TuningSlider {
                leftArrow: "◀"
                rightArrow: "▶"
            }
        }
    }

    // ========================================================
    // SPEAKER DOCK
    // ========================================================

    Rectangle {
        id: speakerDock

        anchors {
            left: parent.left
            right: parent.right
            top: controlDock.bottom
            bottom: utilityDock.top

            leftMargin: 10
            rightMargin: 10
            topMargin: 8
            bottomMargin: 8
        }

        color: root.dock

        border {
            width: 1
            color: root.cyan
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 6

            color: root.dockInner

            border {
                width: 1
                color: root.orange
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 10

            spacing: 4

            Repeater {
                model: Math.max(8, Math.floor((speakerDock.width - 24) / 8) + 1)

                Rectangle {
                    width: 4
                    height: speakerDock.height - 20

                    radius: 2

                    color: "#06020A"

                    border {
                        width: 1
                        color: "#170F1D"
                    }
                }
            }
        }
    }

    // ========================================================
    // LOWER BLANK HARDWARE DOCK
    // ========================================================

    Rectangle {
        id: utilityDock

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom

            leftMargin: 10
            rightMargin: 10
            bottomMargin: 10
        }

        height: 82

        color: root.dock

        border {
            width: 1
            color: root.cyan
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 6

            color: root.dockInner

            border {
                width: 1
                color: root.orange
            }
        }

        Rectangle {
            anchors.centerIn: parent

            width: parent.width - 26
            height: parent.height - 24

            color: "#07010A"

            border {
                width: 1
                color: "#23152A"
            }
        }

        Repeater {
            model: 4

            Rectangle {
                required property int index

                width: 5
                height: 5
                radius: 2.5

                color: "#4C4351"

                x: index % 2 === 0 ? 13 : utilityDock.width - width - 13

                y: index < 2 ? 13 : utilityDock.height - height - 13
            }
        }
    }
}
