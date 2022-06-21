pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property size windowSize: Qt.size(640, 640)

    readonly property int tileSide: 90
    readonly property int tileCorner: 10
    readonly property int tileSpacing: 10

    function tileFontPixelSize(number) {
        return number < 100 ? 60 : number < 1000 ? 50 : number < 10000 ? 40 : 30
    }

    readonly property color backgroundColor: "black"
    readonly property color panelColor: "#333333"
    readonly property color emptyTileColor: "#222222"

    readonly property var tileColors: [
        "#4aa255",
        "#99c35c",
        "#e3db5f",
        "#e3a958",
        "#e27650",
        "#ce7265",
        "#df6a7e",
        "#db5eab",
        "#c185c2",
        "#d6afdf",
        "#d6c6fc",
        "#a7acd9",
        "#8799b0",
        "#668586",
        "white",
        "white"
    ]

    readonly property int moveAnimationSpeed: 150
    readonly property int creationAnimationTime: 100
    readonly property int squashAnimationTime: 100
    readonly property real squashExtentionCoeff: 1.1
}
