import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    id: root

    width: Styles.windowSize.width
    height: Styles.windowSize.height
    visible: true
    title: qsTr("2048")
    color: Styles.backgroundColor

    readonly property int size: 4

    property var values: []
    property var tryBackupMatrix: []
    property var backupMatrix: []

    property var collisionMatrix: []

    property int tryBackupScore: 0
    property int backupScore: 0

    property bool actionInProgress: false

    property bool win: false

    QtObject {
        id: moveTracker

        property int maxDistance: 0
        property var movedTiles: []

        function log() {
            console.debug("Max distance:", maxDistance)
            for (var i = 0; i < movedTiles.length; ++i)
            {
                console.debug("moved", values[movedTiles[i].idx].xIndex, values[movedTiles[i].idx].yIndex, "for",
                             movedTiles[i].xMove === undefined ? movedTiles[i].yMove : movedTiles[i].xMove)
                if (movedTiles[i].squashed !== null)
                    console.debug("which squashes", movedTiles[i].squashed.xIndex, movedTiles[i].squashed.yIndex)
            }
        }

        function clear() {
            movedTiles.splice(0, movedTiles.length)
            maxDistance = 0
        }
    }

    function createTileItem(x, y, number, tileComponent) {
        if (tileComponent === undefined)
        {
            tileComponent = Qt.createComponent("Tile.qml")
        }

        if (tileComponent.status === Component.Ready) {
            var obj = tileComponent.createObject(panel, {
                                                     xIndex: x,
                                                     yIndex: y,
                                                     number: number
                                                 })
            values.push(obj)

            obj.animateCreation()
        }
    }

    function createInitialTiles() {
        var tileComponent = Qt.createComponent("Tile.qml")
        if (tileComponent.status === Component.Ready) {
            generateRandomTile()
            generateRandomTile()
        }
    }

    Component.onCompleted: {
        createInitialTiles()

        createCollisionMatrix()
    }

    function createCollisionMatrix() {
        for (var i = 0; i < size; ++i)
        {
            collisionMatrix.push([])
            for (var j = 0; j < size; ++j)
                collisionMatrix[i].push(0)
        }
    }

    function clearCollisionMatrix() {
        for (var i = 0; i < size; ++i)
        {
            for (var j = 0; j < size; ++j)
            {
                collisionMatrix[i][j] = 0
            }
        }
    }

    function findValue(x, y)
    {
        for (var i = 0; i < values.length; ++i)
        {
            if (values[i].xIndex === x && values[i].yIndex === y)
                return i
        }

        return undefined
    }

    function calculateTileShift(tile, direction)
    {
        var newCoord = Directed.getCoord[direction](tile)
        var collision = false
        var nextTile
        for (var i = Directed.next[direction](Directed.getCoord[direction](tile)); i !== Directed.next[direction](Directed.max[direction](size)); i = Directed.next[direction](i))
        {
            nextTile = Directed.callFindValue[direction](findValue, tile, i)
            if (nextTile === undefined)
            {
                newCoord = i
            }
            else
            {
                if (values[nextTile].number === tile.number &&
                        collisionMatrix[values[nextTile].yIndex][values[nextTile].xIndex] === 0)
                {
                    collision = true
                    newCoord = i
                    collisionMatrix[values[nextTile].yIndex][values[nextTile].xIndex] = 1
                }
                break
            }
        }

        if (newCoord !== Directed.getCoord[direction](tile))
        {
            //console.debug(Directed.str[direction], tile.log) // for debugging

            moveTracker.movedTiles.push({
                                            idx: findValue(tile.xIndex, tile.yIndex),
                                            xMove: Directed.xMoves[direction](newCoord, Directed.getCoord[direction](tile)),
                                            yMove: Directed.yMoves[direction](newCoord, Directed.getCoord[direction](tile)),
                                            squashed: collision ? values[nextTile] : null
                                        })
            moveTracker.maxDistance = Math.max(moveTracker.maxDistance, Math.abs(newCoord - Directed.getCoord[direction](tile)))

            Directed.setCoord[direction](tile, newCoord)
            if (collision)
            {
                tile.number *= 2
                if (tile.number === 2048 && !root.win) {
                    root.win = true
                }
                score.value += tile.number
            }
        }
    }

    function shift(direction)
    {
        for (var i = Directed.previous[direction](Directed.max[direction](size)); i !== Directed.previous[direction](Directed.min[direction](size)); i = Directed.previous[direction](i))
        {
            for (var v = 0; v < values.length; ++v)
            {
                if (Directed.getCoord[direction](values[v]) === i)
                    calculateTileShift(values[v], direction)
            }
        }

        clearCollisionMatrix()
        move()
    }

    function move() {
        if (moveTracker.movedTiles.length > 0)
        {
            root.actionInProgress = true
            backupMatrix = tryBackupMatrix
            backupScore = tryBackupScore

            for (var m = 0; m < moveTracker.movedTiles.length; ++m)
            {
                values[moveTracker.movedTiles[m].idx].animateMove(moveTracker.movedTiles[m].xMove,
                                                              moveTracker.movedTiles[m].yMove,
                                                              moveTracker.movedTiles[m].squashed)
                values[moveTracker.movedTiles[m].idx].squashRequested.connect(squashTile)

            }

            moveAnimationTimer.interval = moveTracker.maxDistance * Styles.moveAnimationSpeed
            moveAnimationTimer.start()
            moveTracker.clear()
            backButton.enabled = true
        }
    }

    function storeState() {
        var matrix = []
        for (var i = 0; i < root.size; ++i)
        {
            matrix.push([])
            for (var j = 0; j < root.size; ++j)
                matrix[i].push(0)
        }

        values.forEach(function(tile) {
            matrix[tile.xIndex][tile.yIndex] = tile.number
        })

        return matrix
    }

    function restoreState() {
        var tileComponent = Qt.createComponent("Tile.qml")
        if (tileComponent.status === Component.Ready) {
            values.forEach(function(tile) { tile.destroy() })
            values.splice(0, values.length)

            for (var i = 0; i < root.size; ++i)
            {
                for (var j = 0; j < root.size; ++j)
                {
                    if (backupMatrix[i][j] !== 0)
                    {
                        createTileItem(i, j, backupMatrix[i][j], tileComponent)
                    }
                }
            }

            score.value = backupScore

            var noWin = true
            for (var v = 0; v < values.length; ++v)
            {
                if (values[v].number > 1024) {
                    noWin = false
                    break
                }
            }
            if (noWin)
                endlessMode.visible = false

        }
        else {
            console.error("Cannot revert previous state!")
        }
    }

    function squashTile(tile) {
        var idx = values.indexOf(tile)
        if (idx !== -1) {
            console.debug("squashing", tile.log)
            tile.destroy()
            values.splice(idx, 1)
        }
    }

    function reset() {
        values.forEach(function(tile) { tile.destroy() })
        values.splice(0, values.length)
        score.value = 0
        win = false
        endlessMode.visible = false
        createInitialTiles()
    }

    function checkGameOver() {
        if (values.length < root.size * root.size)
            return

        for (var x = 0; x < root.size; ++x)
        {
            for (var y = 0; y < root.size; ++y)
            {
                var thisTile = findValue(x, y)

                if (x + 1 < root.size) {
                    // check right tile
                    var rightTile = findValue(x + 1, y)
                    if (values[thisTile].number === values[rightTile].number)
                        return
                }

                if (y + 1 < root.size) {
                    // check below tile
                    var belowTile = findValue(x, y + 1)
                    if (values[thisTile].number === values[belowTile].number)
                        return
                }
            }
        }

        gameOverPopup.open()
    }

    Popup {
        id: gameOverPopup

        anchors.centerIn: parent
        closePolicy: Popup.CloseOnReleaseOutside | Popup.CloseOnEscape
        modal: true
        opacity: 0.7

        contentItem: Text {
            text: "Game over! " + score.text
            font.pixelSize: 50
        }

        onClosed: reset()
    }

    function checkWinCondition() {
        if (root.win) {
            winPopup.open()
            root.win = false
        }
    }

    Popup {
        id: winPopup

        anchors.centerIn: parent
        closePolicy: Popup.CloseOnReleaseOutside | Popup.CloseOnEscape
        modal: true
        opacity: 0.7

        contentItem: Text {
            text: "You have beat the game! Continue in endless mode."
            font.pixelSize: 50
            width: root.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter

        }

        onClosed: endlessMode.visible = true
    }

    Timer {
        id: moveAnimationTimer

        onTriggered: {
            generateRandomTile()
            root.actionInProgress = false
            checkGameOver()
            checkWinCondition()
        }
    }

    function print() { // for debugging
        var matrix = []
        for (var i = 0; i < root.size; ++i)
        {
            matrix.push([])
            for (var j = 0; j < root.size; ++j)
                matrix[i].push(0)
        }

        for (var v = 0; v < values.length; ++v)
        {
            matrix[values[v].yIndex][values[v].xIndex] = values[v].number
        }

        console.info("matrix:")
        for (i = 0; i < root.size; ++i)
        {
            var row = ""
            for (j = 0; j < root.size; ++j)
                row += " " + matrix[i][j]
            console.info(row)
        }
    }

    function generateRandomTile() {
        var x, y
        do {
            x = Math.floor(Math.random() * 100) % root.size
            y = Math.floor(Math.random() * 100) % root.size
        } while (findValue(x, y) !== undefined)

        createTileItem(x, y, Math.floor(Math.random() * 100) < 80 ? 2 : 4) // 80-20 probability split
    }

    Text {
        id: score

        property int value: 0
        text: "Score: " + value
        color: "white"
        font.pixelSize: 70
        anchors {
            bottom: panel.top
            horizontalCenter: panel.horizontalCenter
        }
    }

    Rectangle {
        id: panel

        width: Styles.tileSpacing + (Styles.tileSpacing + Styles.tileSide) * root.size
        height: Styles.tileSpacing + (Styles.tileSpacing + Styles.tileSide) * root.size
        radius: Styles.tileCorner
        color: Styles.panelColor
        anchors.centerIn: parent

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: {
            if (winPopup.opened || gameOverPopup.opened)
                return

            var keys = [Qt.Key_Up, Qt.Key_Down, Qt.Key_Left, Qt.Key_Right]
            if (keys.indexOf(event.key) === -1)
            {
                event.accepted = false
                return
            }

            event.accepted = true

            if (!root.actionInProgress) {
                tryBackupMatrix = storeState()
                tryBackupScore = score.value
                shift(keys.indexOf(event.key))
            }
        }

        Grid {
            x: Styles.tileSpacing
            y: Styles.tileSpacing
            columnSpacing: Styles.tileSpacing
            rowSpacing: Styles.tileSpacing
            rows: root.size

            Repeater {
                model: root.size * root.size
                delegate: Rectangle {
                    color: Styles.emptyTileColor
                    width: 90
                    height: 90
                    radius: 10
                }
            }
        }
    }

    Row {
        id: buttonsRow

        spacing: 10
        anchors {
            top: panel.bottom
            topMargin: 10
            horizontalCenter: panel.horizontalCenter
        }

        Button {
            id: backButton

            text: "Back"
            font.pixelSize: 30

            onClicked: {
                restoreState()
                backButton.enabled = false
                panel.forceActiveFocus()
            }

            Component.onCompleted: enabled = false
        }

        Button {
            id: resetButton

            text: "Reset"
            font.pixelSize: 30

            onClicked: {
                reset()
                panel.forceActiveFocus()
            }
        }
    }

    Text {
        id: endlessMode

        anchors {
            top: buttonsRow.bottom
            topMargin: 10
            horizontalCenter: buttonsRow.horizontalCenter
        }
        text: "Endless mode"
        font.pixelSize: 30
        color: "white"
        visible: false
    }
}
