import QtQuick 2.15

Rectangle {
    id: root

    property int xIndex
    property int yIndex
    property int number

    QtObject {
        id: internal
        property int xCenter
        property int yCenter

        Component.onCompleted: {
            xCenter = Styles.tileSpacing + xIndex * (Styles.tileSpacing + Styles.tileSide) + Styles.tileSide/2
            yCenter = Styles.tileSpacing + yIndex * (Styles.tileSpacing + Styles.tileSide) + Styles.tileSide/2
        }
    }

    property var squashed
    property string log: "%1(%2x%3)".arg(number).arg(xIndex).arg(yIndex)

    signal moveAnimationEnded()
    signal squashRequested(var tile)

    width: Styles.tileSide
    height: Styles.tileSide
    radius: Styles.tileCorner
    x: internal.xCenter - width/2
    y: internal.yCenter - height/2
    color: Styles.tileColors[Math.log(number) / Math.log(2) - 1]

    Component.onCompleted: updateText()

    function animateSquash() {
        squashAnimation.start()
    }

    function animateCreation() {
        creationAnimation.start()
    }

    function squash() {
        moveAnimationEnded.disconnect(squash)

        squashRequested(squashed)
        animateSquash()
    }

    function updateText() {
        textId.text = number
        moveAnimationEnded.disconnect(updateText)
    }

    function animateMove(xMove, yMove, squashedTile) {
        if (squashedTile)
        {
            squashed = squashedTile
            moveAnimationEnded.connect(updateText)
            moveAnimationEnded.connect(squash)
        }

        if (xMove !== undefined) {
            xAnimation.duration = Styles.moveAnimationSpeed * Math.abs(xMove)
            xAnimation.to = Styles.tileSpacing + xIndex * (Styles.tileSpacing + Styles.tileSide) + Styles.tileSide/2

            xAnimation.start()
        }

        if (yMove !== undefined) {
            yAnimation.duration = Styles.moveAnimationSpeed * Math.abs(yMove)
            yAnimation.to = Styles.tileSpacing + yIndex * (Styles.tileSpacing + Styles.tileSide) + Styles.tileSide/2

            yAnimation.start()
        }
    }

    Text {
        id: textId
        anchors.centerIn: parent
        font.pixelSize: Styles.tileFontPixelSize(text)
    }

    PropertyAnimation {
        id: xAnimation

        running: false
        target: internal
        property: "xCenter"
        loops: 1

        onStopped: root.moveAnimationEnded()
    }

    PropertyAnimation {
        id: yAnimation

        running: false
        target: internal
        property: "yCenter"
        loops: 1

        onStopped: root.moveAnimationEnded()
    }

    ParallelAnimation {
        id: creationAnimation

        PropertyAnimation {
            target: root
            property: "width"
            from: 0
            to: Styles.tileSide
            duration: Styles.creationAnimationTime
        }
        PropertyAnimation {
            target: root
            property: "height"
            from: 0
            to: Styles.tileSide
            duration: Styles.creationAnimationTime
        }
    }

    SequentialAnimation {
        id: squashAnimation

        ParallelAnimation {

            PropertyAnimation {
                target: root
                property: "width"
                to: Styles.tileSide * Styles.squashExtentionCoeff
                duration: Styles.squashAnimationTime
            }
            PropertyAnimation {
                target: root
                property: "height"
                to: Styles.tileSide * Styles.squashExtentionCoeff
                duration: Styles.squashAnimationTime
            }
        }

        ParallelAnimation {

            PropertyAnimation {
                target: root
                property: "width"
                to: Styles.tileSide
                duration: Styles.squashAnimationTime
            }
            PropertyAnimation {
                target: root
                property: "height"
                to: Styles.tileSide
                duration: Styles.squashAnimationTime
            }
        }
    }
}
