import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    color: "#1B0623"

    // ========================================================
    // PALETTE
    // ========================================================

    property color dock: "#14041C"
    property color dockInner: "#0C0211"

    property color topSection: "#12041A"
    property color topSectionInner: "#0E0315"

    property color dividerDark: topSection
    property color panelBorder: "#2A1434"

    property color cyan: "#55CFCA"
    property color cyanDim: "#1E6D6A"
    property color orange: "#ED981A"
    property color offwhite: "#DCF3FA"
    property color red: "#D16041"
    property color green: "#00F782"

    property color plastic: "#19171F"
    property color plasticEdge: "#3D3746"
    property color plasticHighlight: "#5E5867"

    property string pixelFont: "GohuFont 11 Nerd Font Mono"

    // Scale only the physical button/switch controls when the deck gets smaller.
    // Power, MODE dial, and the top receiver geometry stay at their normal size.
    property real controlScale: Math.max(0.55, Math.min(1.0, width / 1180, height / 220))

    // Lift the lower hardware slightly into the faceplate instead of hugging the bottom edge.
    property real controlLift: 12

    // Molded ABS-style surface variation. The overlay is deterministic so it
    // never crawls or flickers like CRT/static noise.
    property real grainStrength: 0.13

    component PlasticGrain: Canvas {
        property real density: 0.072
        property real strength: root.grainStrength
        property real mottleStrength: 0.055
        property color lightColor: "#FFFFFF"
        property color darkColor: "#000000"

        anchors.fill: parent
        opacity: strength
        visible: opacity > 0
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onDensityChanged: requestPaint()
        onStrengthChanged: requestPaint()
        onMottleStrengthChanged: requestPaint()

        function hash(n) {
            var x = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
            return x - Math.floor(x);
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            // Broad, low-contrast mottling gives the face the uneven density
            // of molded plastic without looking like a screen effect.
            var patches = Math.max(5, Math.floor((width * height) / 12000));
            for (var p = 0; p < patches; ++p) {
                var hx = hash(p * 7 + 1);
                var hy = hash(p * 7 + 2);
                var hr = hash(p * 7 + 3);
                var hb = hash(p * 7 + 4);
                var cx = hx * width;
                var cy = hy * height;
                var radius = 10 + hr * 28;
                var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius);
                var a = mottleStrength * (0.45 + hb * 0.55);
                var rgb = hb > 0.5 ? "255,255,255" : "0,0,0";
                g.addColorStop(0, "rgba(" + rgb + "," + a + ")");
                g.addColorStop(1, "rgba(" + rgb + ",0)");
                ctx.fillStyle = g;
                ctx.fillRect(cx - radius, cy - radius, radius * 2, radius * 2);
            }

            // Fine embedded grain.
            var step = 3;
            for (var y = 1; y < height - 1; y += step) {
                for (var x = 1; x < width - 1; x += step) {
                    var seed = ((x * 73856093) ^ (y * 19349663)) >>> 0;
                    var r = (seed % 1000) / 1000.0;
                    if (r < density) {
                        var bright = ((seed >> 5) & 1) === 1;
                        ctx.fillStyle = bright ? lightColor : darkColor;
                        ctx.globalAlpha = 0.20 + (((seed >> 10) % 35) / 160.0);
                        var px = x + (seed % 2);
                        var py = y + ((seed >> 2) % 2);
                        ctx.fillRect(px, py, 1, 1);
                        if (((seed >> 7) % 13) === 0)
                            ctx.fillRect(px + 1, py, 1, 1);
                    }
                }
            }
            ctx.globalAlpha = 1.0;
        }
    }

    // ========================================================
    // PHYSICAL BUTTON
    // ========================================================

    component DeckButton: Item {
        id: buttonRoot

        required property string buttonText
        property real uiScale: root.controlScale

        width: 84 * uiScale
        height: 62 * uiScale

        Item {
            width: 84
            height: 62
            scale: buttonRoot.uiScale
            transformOrigin: Item.TopLeft

            Rectangle {
                anchors.fill: parent
                color: "#07010A"

                border {
                    width: 1
                    color: "#281B2E"
                }
            }

            Rectangle {
                x: 5
                y: 5
                width: parent.width - 10
                height: 50

                color: root.plastic
                clip: true

                border {
                    width: 1
                    color: root.plasticEdge
                }

                // The button itself keeps a small physical drop because it is
                // meant to project from its dock.
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: 0.58
                    shadowBlur: 0.20
                    shadowVerticalOffset: 3
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 4
                        rightMargin: 4
                        topMargin: 3
                    }
                    height: 3
                    color: root.plasticHighlight
                    opacity: 0.60
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 4
                        rightMargin: 4
                        bottomMargin: 3
                    }
                    height: 5
                    color: "#070609"
                }

                PlasticGrain {
                    anchors.fill: parent
                    anchors.margins: 2
                    strength: 0.11
                    density: 0.075
                    mottleStrength: 0.040
                }

                Text {
                    anchors.centerIn: parent
                    text: buttonRoot.buttonText
                    color: root.offwhite
                    font {
                        family: root.pixelFont
                        pixelSize: 10
                        bold: true
                    }
                }
            }
        }
    }

    // ========================================================
    // VERTICAL ROCKER
    // ========================================================

    component VerticalRockerSwitch: Item {
        id: rocker

        property bool topActive: true
        property real uiScale: root.controlScale

        width: 44 * uiScale
        height: 88 * uiScale

        Item {
            width: 44
            height: 88
            scale: rocker.uiScale
            transformOrigin: Item.TopLeft

            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 76
                color: "#07010A"

                border {
                    width: 1
                    color: "#281D30"
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 3
                    }
                    height: 31
                    color: rocker.topActive ? root.plastic : "#09060B"
                    clip: true

                    border {
                        width: 1
                        color: root.plasticEdge
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 3
                            rightMargin: 3
                            topMargin: 2
                        }
                        height: 2
                        color: root.plasticHighlight
                        opacity: rocker.topActive ? 0.60 : 0.16
                    }

                    PlasticGrain {
                        anchors.fill: parent
                        anchors.margins: 2
                        strength: 0.10
                        density: 0.075
                        mottleStrength: 0.035
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 3
                    }
                    height: 31
                    color: rocker.topActive ? "#09060B" : root.plastic
                    clip: true

                    border {
                        width: 1
                        color: root.plasticEdge
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 3
                            rightMargin: 3
                            topMargin: 2
                        }
                        height: 2
                        color: root.plasticHighlight
                        opacity: rocker.topActive ? 0.16 : 0.60
                    }

                    PlasticGrain {
                        anchors.fill: parent
                        anchors.margins: 2
                        strength: 0.10
                        density: 0.075
                        mottleStrength: 0.035
                    }
                }
            }
        }
    }

    // ========================================================
    // MODE DIAL
    // ========================================================

    component ModeDial: Item {
        id: dialRoot

        width: 112
        height: 110

        Text {
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 7
                topMargin: 8
            }
            text: "MODE"
            color: root.offwhite
            font {
                family: root.pixelFont
                pixelSize: 9
                bold: true
            }
        }

        Item {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 20
            }
            width: 88
            height: 88

            // Dock well.
            Rectangle {
                anchors.centerIn: parent
                width: 88
                height: 88
                radius: 44
                color: "#060108"
                border {
                    width: 2
                    color: "#332238"
                }
            }

            // Offset lower-right ring. This makes the dial stand proud of the
            // dock without a fuzzy drop shadow or transparent line.
            Rectangle {
                x: 7
                y: 9
                width: 78
                height: 78
                radius: 39
                color: "#09060D"
                border {
                    width: 1
                    color: "#211827"
                }
            }

            // Thin raised surrounding ring.
            Rectangle {
                anchors.centerIn: parent
                width: 82
                height: 82
                radius: 41
                color: "#121018"
                border {
                    width: 1
                    color: "#49414F"
                }
            }

            // Main dial face: deliberately flatter, like the physical buttons.
            Rectangle {
                id: modeBody
                anchors.centerIn: parent
                width: 76
                height: 76
                radius: 38
                color: root.plastic
                clip: true

                border {
                    width: 1
                    color: root.plasticEdge
                }

                // small upper material highlight rather than a glow/shadow
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 12
                        rightMargin: 12
                        topMargin: 4
                    }
                    height: 2
                    radius: 1
                    color: root.plasticHighlight
                    opacity: 0.38
                }

                PlasticGrain {
                    anchors.fill: parent
                    anchors.margins: 2
                    strength: 0.10
                    density: 0.070
                    mottleStrength: 0.035
                }

                // Number divider ring.
                Rectangle {
                    anchors.centerIn: parent
                    width: 62
                    height: 62
                    radius: 31
                    color: "transparent"
                    border {
                        width: 2
                        color: root.cyan
                    }
                }

                Repeater {
                    model: ["N", "P", "T", "R", "M", "S"]

                    Text {
                        required property int index
                        required property var modelData
                        text: modelData
                        color: index === 0 ? root.orange : root.cyan
                        font {
                            family: root.pixelFont
                            pixelSize: 7
                        }
                        property real a: (Math.PI * 2 * index / 6) - Math.PI / 2
                        property real r: 24
                        x: modeBody.width / 2 + Math.cos(a) * r - width / 2
                        y: modeBody.height / 2 + Math.sin(a) * r - height / 2
                    }
                }

                // Offset inner shadow plate. It is a physical layer, not an effect.
                Rectangle {
                    x: (parent.width - 31) / 2 + 2
                    y: (parent.height - 31) / 2 + 3
                    width: 31
                    height: 31
                    radius: 15.5
                    color: "#09060C"
                    border {
                        width: 1
                        color: "#18121C"
                    }
                }

                // Raised center shoulder.
                Rectangle {
                    anchors.centerIn: parent
                    width: 29
                    height: 29
                    radius: 14.5
                    color: "#28232D"
                    border {
                        width: 1
                        color: "#5B5361"
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 7
                            rightMargin: 7
                            topMargin: 4
                        }
                        height: 2
                        radius: 1
                        color: "#77717D"
                        opacity: 0.46
                    }
                }

                // White central boss remains underneath the handle.
                Rectangle {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    radius: 7.5
                    color: root.offwhite
                    border {
                        width: 1
                        color: "#A0B2B7"
                    }
                }

                // Full-diameter selector handle. The dark lower layer gives the
                // bar thickness; the orange marker is inset into the white face.
                Item {
                    anchors.centerIn: parent
                    width: 66
                    height: 10
                    transformOrigin: Item.Center
                    rotation: -90

                    Rectangle {
                        x: 2
                        y: 4
                        width: 62
                        height: 6
                        radius: 0
                        color: "#78858A"
                    }

                    Rectangle {
                        x: 2
                        y: 1
                        width: 62
                        height: 6
                        radius: 0
                        color: root.offwhite
                        border {
                            width: 1
                            color: "#B8C8CC"
                        }
                    }

                    // Narrow inset marker: white remains visible on all four sides.
                    Rectangle {
                        x: 56
                        y: 2
                        width: 4
                        height: 4
                        radius: 0
                        color: root.orange
                    }
                }
            }
        }
    }

    // ========================================================
    // TOP RECEIVER BACKGROUND
    // ========================================================

    Rectangle {
        id: upperBackground

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: deckDivider.y

        color: root.topSection

        z: 0
    }

    // ========================================================
    // TOP EDGE
    // ========================================================

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: 2

        color: root.cyan

        z: 10
    }

    // ========================================================
    // SMALL RIGHT INFORMATION PANEL
    //
    // Left edge remains where it was.
    // Width grows to the RIGHT so its outside edge lines up
    // with the MODE dial dock's 14px right margin.
    // ========================================================

    Rectangle {
        id: cornerPanel

        anchors {
            right: parent.right
            top: parent.top

            rightMargin: 14
            topMargin: 18
        }

        // Old:
        // width 152 + rightMargin 28
        //
        // New:
        // width 166 + rightMargin 14
        //
        // So the LEFT EDGE stays in the same place.
        width: 166
        height: 106

        color: root.topSection

        z: 5

        border {
            width: 1
            color: root.panelBorder
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 7

            color: "#100317"

            border {
                width: 1
                color: "#26102F"
            }
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top

                leftMargin: 15
                rightMargin: 12
                topMargin: 17
            }

            text: "A BETTER\n" + "COMMAND LINE\n" + "EXPERIENCE"

            color: root.offwhite

            font {
                family: root.pixelFont
                pixelSize: 11
                bold: true
            }

            lineHeight: 1.15
        }
    }

    // ========================================================
    // DISPLAY
    // Recess reads primarily from the TOP and RIGHT, like a screen pushed
    // back into the receiver face rather than surrounded by four equal rails.
    // ========================================================

    Rectangle {
        id: displayBezel

        anchors {
            right: cornerPanel.left
            top: cornerPanel.top
            rightMargin: 12
        }

        width: Math.min(785, parent.width * 0.405)
        height: 106
        color: "#100316"
        z: 4

        border {
            width: 1
            color: "#32153B"
        }

        // Top and right molded recess faces only.
        Canvas {
            anchors.fill: parent
            z: 0

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var w = width;
                var h = height;
                var cut = 15;

                // deep upper shelf
                ctx.fillStyle = "#050108";
                ctx.beginPath();
                ctx.moveTo(4, 4);
                ctx.lineTo(w - 4, 4);
                ctx.lineTo(w - cut, cut);
                ctx.lineTo(12, cut);
                ctx.closePath();
                ctx.fill();

                // subtle top material catch
                ctx.fillStyle = "#3A2043";
                ctx.beginPath();
                ctx.moveTo(5, 4);
                ctx.lineTo(w - 6, 4);
                ctx.lineTo(w - 11, 8);
                ctx.lineTo(8, 8);
                ctx.closePath();
                ctx.fill();

                // deep right-hand wall
                ctx.fillStyle = "#060109";
                ctx.beginPath();
                ctx.moveTo(w - 4, 4);
                ctx.lineTo(w - 4, h - 5);
                ctx.lineTo(w - cut, h - 10);
                ctx.lineTo(w - cut, cut);
                ctx.closePath();
                ctx.fill();

                // right lip / plastic catch
                ctx.fillStyle = "#41244A";
                ctx.beginPath();
                ctx.moveTo(w - 8, 8);
                ctx.lineTo(w - 5, 5);
                ctx.lineTo(w - 5, h - 7);
                ctx.lineTo(w - 8, h - 10);
                ctx.closePath();
                ctx.fill();
            }
        }

        // Actual VFD glass is shifted down/left so the top and right cavity
        // remain visible. Left and bottom stay nearly flush to the chassis.
        Rectangle {
            id: displayDock
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 7
                rightMargin: 16
                topMargin: 15
                bottomMargin: 6
            }

            color: "#020005"
            z: 1

            border {
                width: 1
                color: root.orange
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                color: "#040108"
                border {
                    width: 1
                    color: "#16071D"
                }
            }

            // Connected top/right internal rails visually meet the recess faces.
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 7
                    rightMargin: 8
                    topMargin: 4
                }
                height: 1
                color: "#6B3F1C"
                opacity: 0.75
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: 7
                    topMargin: 4
                    bottomMargin: 5
                }
                width: 1
                color: "#6B3F1C"
                opacity: 0.75
            }

            Canvas {
                anchors.fill: parent
                z: 1
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#6B3F1C";
                    ctx.lineWidth = 1;
                    ctx.globalAlpha = 0.75;
                    ctx.beginPath();
                    ctx.moveTo(width - 17, 4);
                    ctx.lineTo(width - 8, 13);
                    ctx.stroke();
                    ctx.globalAlpha = 1.0;
                }
            }

            // Main text area, moved inward from the frame.
            Column {
                z: 3
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 18
                    topMargin: 12
                }
                spacing: 2

                Row {
                    spacing: 12
                    Text {
                        text: "SESSION"
                        color: root.cyan
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: "03"
                        color: root.orange
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Item {
                        width: 24
                        height: 1
                    }
                    Text {
                        text: "TAB"
                        color: root.cyan
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: "02"
                        color: root.orange
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Row {
                    spacing: 12
                    Text {
                        text: "MODE"
                        color: root.cyan
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: "NORMAL"
                        color: root.orange
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Row {
                    spacing: 12
                    Text {
                        text: "CONTROL"
                        color: root.cyan
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: "PANE"
                        color: root.orange
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Row {
                    spacing: 12
                    Text {
                        text: "SOURCE"
                        color: root.cyan
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        text: "ZELLIJ"
                        color: root.orange
                        font.family: root.pixelFont
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }

            // Physical separator inside the display: main state to the left,
            // current live indicators to the right.
            Rectangle {
                id: displaySeparator
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    topMargin: 9
                    bottomMargin: 9
                    rightMargin: 105
                }
                width: 1
                color: root.orange
                opacity: 0.55
                z: 3
            }

            Rectangle {
                anchors {
                    left: displaySeparator.left
                    right: parent.right
                    top: parent.top
                    leftMargin: -5
                    rightMargin: 9
                    topMargin: 9
                }
                height: 1
                color: root.orange
                opacity: 0.34
                z: 3
            }

            Column {
                z: 3
                anchors {
                    left: displaySeparator.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 14
                    rightMargin: 12
                }
                spacing: 10

                Row {
                    spacing: 6
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.orange
                    }
                    Text {
                        text: "PANE"
                        color: root.orange
                        font {
                            family: root.pixelFont
                            pixelSize: 10
                            bold: true
                        }
                    }
                }

                Row {
                    spacing: 6
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.green
                    }
                    Text {
                        text: "ZELLIJ"
                        color: root.green
                        font {
                            family: root.pixelFont
                            pixelSize: 10
                            bold: true
                        }
                    }
                }
            }
        }
    }

    // ========================================================
    // EJECT
    // ========================================================

    Item {
        id: ejectControl

        anchors {
            right: displayBezel.left
            top: displayBezel.top
            rightMargin: 58
            topMargin: -2
        }

        width: 58
        height: 80
        z: 5

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 7
            }
            text: "EJECT"
            color: root.offwhite
            font {
                family: root.pixelFont
                pixelSize: 8
                bold: true
            }
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 21
            }
            width: 46
            height: 46
            color: "#07010A"
            border {
                width: 1
                color: "#281B2E"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                color: root.plastic
                clip: true
                border {
                    width: 1
                    color: root.plasticEdge
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 3
                        rightMargin: 3
                        topMargin: 2
                    }
                    height: 3
                    color: root.plasticHighlight
                    opacity: 0.60
                }

                PlasticGrain {
                    anchors.fill: parent
                    anchors.margins: 2
                    strength: 0.11
                    density: 0.075
                    mottleStrength: 0.038
                }

                Text {
                    anchors.centerIn: parent
                    text: "⏏"
                    color: root.offwhite
                    font {
                        family: root.pixelFont
                        pixelSize: 16
                        bold: true
                    }
                }
            }
        }
    }

    // ========================================================
    // DVD FRONT PANEL
    // ========================================================

    Rectangle {
        id: mediaDock

        anchors {
            left: parent.left
            right: ejectControl.left
            top: displayBezel.top
            leftMargin: 36
            rightMargin: 7
        }

        height: 106
        color: "#180723"
        border {
            width: 2
            color: root.panelBorder
        }
        z: 4

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            color: "#12041B"
            border {
                width: 1
                color: "#34203E"
            }
        }

        // Dark lower bed makes the front door look physically thicker.
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 10
                rightMargin: 10
                topMargin: 13
                bottomMargin: 7
            }
            color: "#09020D"
        }

        Rectangle {
            id: dvdFace
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 11
                rightMargin: 11
                topMargin: 9
                bottomMargin: 14
            }

            color: "#251130"
            clip: true
            border {
                width: 1
                color: "#4B3852"
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 3
                    rightMargin: 3
                    topMargin: 3
                }
                height: 5
                color: "#705D79"
                opacity: 0.72
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 3
                    rightMargin: 3
                    bottomMargin: 3
                }
                height: 7
                color: "#08020C"
                opacity: 0.94
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 12
                    topMargin: 6
                    bottomMargin: 6
                }
                width: 2
                color: root.dividerDark
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: 12
                    topMargin: 6
                    bottomMargin: 6
                }
                width: 2
                color: root.dividerDark
            }

            PlasticGrain {
                anchors.fill: parent
                anchors.margins: 2
                strength: 0.14
                density: 0.078
                mottleStrength: 0.060
            }

            Row {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 24
                    topMargin: 7
                }
                spacing: 8

                Text {
                    text: "✦"
                    color: root.orange
                    font {
                        family: root.pixelFont
                        pixelSize: 31
                        bold: true
                    }
                }

                Text {
                    text: "✦"
                    color: root.cyan
                    font {
                        family: root.pixelFont
                        pixelSize: 31
                        bold: true
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "A Post-Apollo//Experience"
                    color: root.offwhite
                    font {
                        family: root.pixelFont
                        pixelSize: 22
                        bold: true
                    }
                }
            }

            Text {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 28
                    topMargin: 41
                }
                text: "DIGITAL VIDEO / DATA DECK"
                color: root.cyan
                font {
                    family: root.pixelFont
                    pixelSize: 13
                    bold: true
                }
            }

            Text {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: 28
                    bottomMargin: 8
                }
                text: "DVD / TERMINAL"
                color: root.offwhite
                font {
                    family: root.pixelFont
                    pixelSize: 11
                    bold: true
                }
            }
        }
    }

    // ========================================================
    // SOLID MIDDLE DIVIDER
    // Physical seam between the upper equipment bay and lower fascia.
    // ========================================================

    Rectangle {
        id: deckDivider

        anchors {
            left: parent.left
            right: parent.right
            top: mediaDock.bottom
            topMargin: 0
        }

        height: 12
        color: "#040006"
        z: 6

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 5
                rightMargin: 5
            }

            height: 2
            color: "#321A3B"
            opacity: 0.78
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 2
                rightMargin: 2
            }

            height: 5
            color: "#020003"
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 7
                rightMargin: 7
            }

            height: 2
            color: "#3A1D45"
            opacity: 0.58
        }
    }

    // ========================================================
    // LOWER RECEIVER
    // ========================================================

    Item {
        id: lowerDeck

        anchors {
            left: parent.left
            right: parent.right
            top: deckDivider.bottom
            bottom: parent.bottom
        }

        z: 2

        // ====================================================
        // RAISED LOWER PLASTIC FASCIA
        // ====================================================

        // Main molded shell.
        Rectangle {
            anchors.fill: parent
            color: "#1B0825"
            z: 0
            clip: true

            border {
                width: 1
                color: "#3A1C45"
            }

            PlasticGrain {
                anchors.fill: parent
                anchors.margins: 1
                strength: 0.10
                density: 0.072
                mottleStrength: 0.060
            }
        }

        // Slightly raised front plane.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: "#200A2B"
            z: 0
            clip: true

            border {
                width: 1
                color: "#32173B"
            }

            PlasticGrain {
                anchors.fill: parent
                anchors.margins: 1
                strength: 0.13
                density: 0.074
                mottleStrength: 0.066
            }
        }

        // Stronger shallow top face: the lower deck now visibly projects a
        // little toward the viewer without becoming glossy.
        Canvas {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 4
                rightMargin: 4
                topMargin: 2
            }
            height: 20
            z: 1

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var w = width;
                var h = height;

                ctx.fillStyle = "#2A1234";
                ctx.beginPath();
                ctx.moveTo(2, 0);
                ctx.lineTo(w - 2, 0);
                ctx.lineTo(w - 12, h);
                ctx.lineTo(12, h);
                ctx.closePath();
                ctx.fill();

                ctx.fillStyle = "#4A2B52";
                ctx.globalAlpha = 0.40;
                ctx.beginPath();
                ctx.moveTo(3, 1);
                ctx.lineTo(w - 3, 1);
                ctx.lineTo(w - 7, 5);
                ctx.lineTo(7, 5);
                ctx.closePath();
                ctx.fill();
                ctx.globalAlpha = 1.0;

                ctx.fillStyle = "#09020D";
                ctx.beginPath();
                ctx.moveTo(12, h - 4);
                ctx.lineTo(w - 12, h - 4);
                ctx.lineTo(w - 12, h);
                ctx.lineTo(12, h);
                ctx.closePath();
                ctx.fill();
            }
        }

        // Far edges reinforce the protruding piece of plastic.
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 4
                topMargin: 5
                bottomMargin: 5
            }
            width: 4
            color: "#35183F"
            opacity: 0.74
            z: 1
        }

        Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 4
                topMargin: 5
                bottomMargin: 5
            }
            width: 4
            color: "#07010A"
            opacity: 0.92
            z: 1
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 5
                rightMargin: 5
                bottomMargin: 4
            }
            height: 11
            color: "#060108"
            opacity: 0.92
            z: 1
        }

        // ====================================================
        // POWER
        // ====================================================

        Rectangle {
            id: powerDock

            z: 3

            anchors {
                left: parent.left
                bottom: parent.bottom

                leftMargin: 14
                bottomMargin: 8 + root.controlLift
            }

            width: 94

            height: Math.min(108, lowerDeck.height - (8 + root.controlLift))

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

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top

                    topMargin: 9
                }

                text: "POWER"
                color: root.offwhite

                font {
                    family: root.pixelFont
                    pixelSize: 9
                    bold: true
                }
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom

                    bottomMargin: 8
                }

                width: 58
                height: 74

                color: "#07010A"

                border {
                    width: 1
                    color: "#4D202A"
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5

                    color: root.plastic
                    clip: true

                    border {
                        width: 2
                        color: root.red
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top

                            leftMargin: 5
                            rightMargin: 5
                            topMargin: 3
                        }

                        height: 4

                        color: "#6C454E"
                    }

                    PlasticGrain {
                        anchors.fill: parent
                        anchors.margins: 2
                        strength: 0.12
                        density: 0.075
                        mottleStrength: 0.040
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "⏻"
                        color: root.red

                        font {
                            family: root.pixelFont
                            pixelSize: 25
                            bold: true
                        }
                    }
                }
            }
        }

        // ====================================================
        // MODE DIAL
        // ====================================================

        Rectangle {
            id: modeDock

            z: 3

            anchors {
                right: parent.right
                bottom: parent.bottom

                rightMargin: 14
                bottomMargin: 8 + root.controlLift
            }

            width: 130
            height: Math.min(110, lowerDeck.height - (8 + root.controlLift))

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

            ModeDial {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter

                    verticalCenterOffset: -6
                }

                scale: 0.88
            }
        }

        // ====================================================
        // SWITCH DOCK
        // ====================================================

        Rectangle {
            id: switchesDock

            z: 3

            anchors {
                right: modeDock.left
                verticalCenter: modeDock.verticalCenter

                rightMargin: 16
            }

            width: 110 * root.controlScale
            height: 90 * root.controlScale

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
                    color: root.dividerDark
                }
            }

            Row {
                anchors.centerIn: parent

                spacing: 8 * root.controlScale

                VerticalRockerSwitch {
                    uiScale: root.controlScale
                }
                VerticalRockerSwitch {
                    uiScale: root.controlScale
                }
            }
        }

        // ====================================================
        // BUTTON AREA
        // ====================================================

        Item {
            id: buttonArea

            z: 3

            anchors {
                left: powerDock.right
                right: switchesDock.left
                bottom: parent.bottom

                leftMargin: 18
                rightMargin: 18
                bottomMargin: 8 + root.controlLift
            }

            height: 82 * root.controlScale

            // =================================================
            // NEW / CLOSE
            // =================================================

            Rectangle {
                id: editDock

                anchors {
                    left: parent.left
                    bottom: parent.bottom

                    leftMargin: 42 * root.controlScale
                }

                width: 212 * root.controlScale
                height: 82 * root.controlScale

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
                        color: root.dividerDark
                    }
                }

                Row {
                    anchors.centerIn: parent

                    spacing: 22 * root.controlScale

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "NEW"
                    }

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "CLOSE"
                    }
                }
            }

            // =================================================
            // FULL / FLOAT / RENAME
            // =================================================

            Rectangle {
                id: windowDock

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter

                    horizontalCenterOffset: -275 * root.controlScale
                }

                width: 322 * root.controlScale
                height: 82 * root.controlScale

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
                        color: root.dividerDark
                    }
                }

                Row {
                    anchors.centerIn: parent

                    spacing: 12 * root.controlScale

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "FULL"
                    }

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "FLOAT"
                    }

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "RENAME"
                    }
                }
            }

            // =================================================
            // PIN / FRAME / SYNC
            // =================================================

            Rectangle {
                id: utilityButtonDock

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter

                    horizontalCenterOffset: 275 * root.controlScale
                }

                width: 298 * root.controlScale
                height: 82 * root.controlScale

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
                        color: root.dividerDark
                    }
                }

                Row {
                    anchors.centerIn: parent

                    spacing: 10 * root.controlScale

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "PIN"
                    }

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "FRAME"
                    }

                    DeckButton {
                        uiScale: root.controlScale
                        buttonText: "SYNC"
                    }
                }
            }

            // =================================================
            // OPTION
            // =================================================

            Rectangle {
                id: optionDock

                anchors {
                    right: parent.right
                    bottom: parent.bottom

                    rightMargin: 30 * root.controlScale
                }

                width: 104 * root.controlScale
                height: 82 * root.controlScale

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
                        color: root.dividerDark
                    }
                }

                DeckButton {
                    anchors.centerIn: parent
                    uiScale: root.controlScale
                    buttonText: "OPTION"
                }
            }
        }
    }
}
