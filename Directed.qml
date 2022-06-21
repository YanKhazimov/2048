pragma Singleton
import QtQuick 2.0

QtObject {
    id: root

    readonly property var str : ["up", "down", "left", "right"]
    readonly property var max : [
        function(size){return 0},
        function(size){return size - 1},
        function(size){return 0},
        function(size){return size - 1}
    ]
    readonly property var min : [
        function(size){return size - 1},
        function(size){return 0},
        function(size){return size - 1},
        function(size){return 0}
    ]
    readonly property var next : [
        function(n){return n - 1},
        function(n){return n + 1},
        function(n){return n - 1},
        function(n){return n + 1}
    ]
    readonly property var previous : [
        function(n){return n + 1},
        function(n){return n - 1},
        function(n){return n + 1},
        function(n){return n - 1}
    ]
    readonly property var getCoord : [
        function(tile){return tile.yIndex},
        function(tile){return tile.yIndex},
        function(tile){return tile.xIndex},
        function(tile){return tile.xIndex}
    ]
    readonly property var setCoord : [
        function(tile, value){tile.yIndex = value},
        function(tile, value){tile.yIndex = value},
        function(tile, value){tile.xIndex = value},
        function(tile, value){tile.xIndex = value}
    ]
    readonly property var xMoves : [
        function(newCoord, coord){return undefined},
        function(newCoord, coord){return undefined},
        function(newCoord, coord){return coord - newCoord},
        function(newCoord, coord){return newCoord - coord}
    ]
    readonly property var yMoves : [
        function(newCoord, coord){return coord - newCoord},
        function(newCoord, coord){return newCoord - coord},
        function(newCoord, coord){return undefined},
        function(newCoord, coord){return undefined}
    ]
    readonly property var callFindValue : [
        function(callback, tile, i){return callback(tile.xIndex, i)},
        function(callback, tile, i){return callback(tile.xIndex, i)},
        function(callback, tile, i){return callback(i, tile.yIndex)},
        function(callback, tile, i){return callback(i, tile.yIndex)}
    ]
}
