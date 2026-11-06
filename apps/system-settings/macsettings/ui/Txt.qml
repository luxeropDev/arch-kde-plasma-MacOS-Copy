import QtQuick

Text {
    property bool secondary: false
    color: secondary ? Theme.secondary : Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
