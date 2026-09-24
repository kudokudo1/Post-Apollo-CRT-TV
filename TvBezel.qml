import QtQuick

Item {
    id: root

    required property string edge

    property color outerPlastic: "#211527"
    property color outerHighlight: "#4A3A52"
    property color outerShadow: "#08050A"

    property color innerPlastic: "#130818"
    property color innerHighlight: "#3A2942"
    property color innerShadow: "#050307"

    property color seam: "#704553"
    property color orange: "#ED981A"

    Canvas {
        id: canvas
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function polygon(ctx, points, color) {
            ctx.beginPath();
            ctx.moveTo(points[0][0], points[0][1]);
            for (var i = 1; i < points.length; ++i)
                ctx.lineTo(points[i][0], points[i][1]);
            ctx.closePath();
            ctx.fillStyle = color;
            ctx.fill();
        }

        function line(ctx, points, color, width) {
            ctx.beginPath();
            ctx.moveTo(points[0][0], points[0][1]);
            for (var i = 1; i < points.length; ++i)
                ctx.lineTo(points[i][0], points[i][1]);
            ctx.strokeStyle = color;
            ctx.lineWidth = width;
            ctx.stroke();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            var d = Math.max(8, Math.min(16, Math.min(w, h) * 0.42));
            var split;

            ctx.fillStyle = root.outerPlastic;
            ctx.fillRect(0, 0, w, h);

            if (root.edge === "top") {
                split = h * 0.52;

                polygon(ctx, [
                    [0, h],
                    [d, split],
                    [w - d, split],
                    [w, h]
                ], root.innerPlastic);

                line(ctx, [
                    [0, h],
                    [d, split],
                    [w - d, split],
                    [w, h]
                ], root.seam, 2);

                line(ctx, [[2, 2], [w - 2, 2]], root.outerHighlight, 2);
                line(ctx, [[d + 2, split + 3], [w - d - 2, split + 3]], root.innerHighlight, 1);
                line(ctx, [[d + 2, split - 1], [w - d - 2, split - 1]], root.orange, 1);

            } else if (root.edge === "bottom") {
                split = h * 0.48;

                polygon(ctx, [
                    [0, 0],
                    [d, split],
                    [w - d, split],
                    [w, 0]
                ], root.innerPlastic);

                line(ctx, [
                    [0, 0],
                    [d, split],
                    [w - d, split],
                    [w, 0]
                ], root.seam, 2);

                line(ctx, [[2, h - 2], [w - 2, h - 2]], root.outerShadow, 2);
                line(ctx, [[d + 2, split - 3], [w - d - 2, split - 3]], root.innerShadow, 1);
                line(ctx, [[d + 2, split + 1], [w - d - 2, split + 1]], root.orange, 1);

            } else if (root.edge === "left") {
                split = w * 0.52;

                polygon(ctx, [
                    [w, 0],
                    [split, d],
                    [split, h - d],
                    [w, h]
                ], root.innerPlastic);

                line(ctx, [
                    [w, 0],
                    [split, d],
                    [split, h - d],
                    [w, h]
                ], root.seam, 2);

                line(ctx, [[2, 2], [2, h - 2]], root.outerHighlight, 2);
                line(ctx, [[split + 3, d + 2], [split + 3, h - d - 2]], root.innerHighlight, 1);
                line(ctx, [[split - 1, d + 2], [split - 1, h - d - 2]], root.orange, 1);

            } else {
                split = w * 0.48;

                polygon(ctx, [
                    [0, 0],
                    [split, d],
                    [split, h - d],
                    [0, h]
                ], root.innerPlastic);

                line(ctx, [
                    [0, 0],
                    [split, d],
                    [split, h - d],
                    [0, h]
                ], root.seam, 2);

                line(ctx, [[w - 2, 2], [w - 2, h - 2]], root.outerShadow, 2);
                line(ctx, [[split - 3, d + 2], [split - 3, h - d - 2]], root.innerShadow, 1);
                line(ctx, [[split + 1, d + 2], [split + 1, h - d - 2]], root.orange, 1);
            }
        }
    }
}
