import QtQuick

// A slot's icon, its ink centred in the item so it turns and stretches about its middle.
// "spin" turns it, "stretch" pulls it along its diagonal (the ruler), "cut" snips the
// scissors: each half of the glyph is two opposite quadrants turning about the pivot.
Item {
  id: icon

  property var item: null
  property string fontFamily
  // Set by the menu once it has been held long enough to play the animations.
  property bool lively: false
  property real size: 26
  property color color
  readonly property string glyph: item && item.glyph ? item.glyph : ""
  readonly property string animation: item && item.animation ? item.animation : ""
  readonly property bool playing: icon.lively && animation !== ""
  property real stretch: 1
  property real snip: 0

  visible: glyph !== ""
  width: Math.round(size * 1.25)
  height: width

  TextMetrics {
    id: ink
    text: icon.glyph
    font.family: icon.fontFamily
    font.pixelSize: icon.size
  }

  transform: [
    Rotation { origin.x: icon.width / 2; origin.y: icon.height / 2; angle: 45 },
    Scale { origin.x: icon.width / 2; origin.y: icon.height / 2; xScale: icon.stretch },
    Rotation { origin.x: icon.width / 2; origin.y: icon.height / 2; angle: -45 }
  ]

  RotationAnimation on rotation {
    running: icon.playing && icon.animation === "spin"
    from: 0
    to: 360
    duration: 2400
    loops: Animation.Infinite
  }

  SequentialAnimation on stretch {
    running: icon.playing && icon.animation === "stretch"
    loops: Animation.Infinite
    NumberAnimation { to: 1.35; duration: 600; easing.type: Easing.InOutQuad }
    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutQuad }
  }

  SequentialAnimation on snip {
    running: icon.playing && icon.animation === "cut"
    loops: Animation.Infinite
    NumberAnimation { to: 1; duration: 160; easing.type: Easing.InQuad }
    NumberAnimation { to: 0; duration: 320; easing.type: Easing.OutQuad }
    PauseAnimation { duration: 200 }
  }

  // Quadrants 0..3: top left, top right, bottom left, bottom right. Uncut, they put the
  // whole glyph back together.
  Repeater {
    model: icon.animation === "cut" ? 4 : 1

    Item {
      id: part

      required property int index
      readonly property bool whole: icon.animation !== "cut"
      readonly property int col: index % 2
      readonly property int row: Math.floor(index / 2)

      x: whole ? 0 : col * icon.width / 2
      y: whole ? 0 : row * icon.height / 2
      width: whole ? icon.width : icon.width / 2
      height: whole ? icon.height : icon.height / 2
      clip: !whole
      transformOrigin: whole ? Item.Center : [Item.BottomRight, Item.BottomLeft, Item.TopRight, Item.TopLeft][index]
      // Top left and bottom right are one blade with its handle, the other two the other.
      rotation: whole ? 0 : (col === row ? -1 : 1) * 30 * icon.snip

      Text {
        x: icon.width / 2 - ink.tightBoundingRect.x - ink.tightBoundingRect.width / 2 - part.x
        y: icon.height / 2 - baselineOffset - ink.tightBoundingRect.y - ink.tightBoundingRect.height / 2 - part.y
        text: icon.glyph
        font: ink.font
        color: icon.color
      }
    }
  }
}
