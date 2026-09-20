import QtQuick
import qs.Commons
import qs.Ui

// Modal shown before pairing a device that may require a PIN/passkey.
//
// The PIN field is optional: leaving it blank pairs exactly like the stock
// omarchy widget, while entering one routes through a PIN-aware agent. Escape
// cancels; Enter submits. While `busy` the dialog is locked so a stray key or
// click cannot start a second pairing.
Item {
  id: root

  property bool opened: false
  property bool busy: false
  property bool pinEnabled: true
  property string deviceLabel: ""
  property string message: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  signal canceled()
  signal submitted(string pin)

  visible: opened
  z: 100

  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.72)

    MouseArea {
      anchors.fill: parent
      onClicked: if (!root.busy) root.canceled()
    }
  }

  BorderSurface {
    id: card
    width: Math.min(parent.width - Style.space(32), Style.space(360))
    height: body.implicitHeight + Style.space(36)
    anchors.centerIn: parent
    color: Color.background
    borderSpec: Border.flat(root.accent, Style.normalBorderWidth)
    radius: Style.cornerRadius

    // Swallow clicks so they don't fall through to the scrim's cancel handler.
    MouseArea { anchors.fill: parent }

    Column {
      id: body
      anchors.fill: parent
      anchors.margins: Style.space(18)
      spacing: Style.space(12)

      Text {
        textFormat: Text.PlainText
        text: "Pair device"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Text {
        textFormat: Text.PlainText
        text: root.deviceLabel
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
        width: parent.width
      }

      Text {
        textFormat: Text.PlainText
        visible: root.pinEnabled
        text: "Enter the device's PIN or passkey, then try again."
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        width: parent.width
      }

      TextField {
        id: pinField
        width: parent.width
        visible: root.pinEnabled
        enabled: !root.busy
        placeholderText: "PIN / passkey (optional)"
        foreground: root.foreground
        accent: root.accent
        onAccepted: if (!root.busy) root.submitted(text)
        Keys.onEscapePressed: if (!root.busy) root.canceled()
      }

      Text {
        textFormat: Text.PlainText
        visible: root.message !== ""
        text: root.message
        color: Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        width: parent.width
      }

      Row {
        anchors.right: parent.right
        spacing: Style.space(10)

        DialogButton {
          text: "Cancel"
          enabled: !root.busy
          onClicked: root.canceled()
        }

        DialogButton {
          text: root.pinEnabled ? (root.busy ? "Pairing…" : "Pair") : "Close"
          enabled: !root.busy
          destructive: false
          onClicked: root.pinEnabled ? root.submitted(pinField.text) : root.canceled()
        }
      }
    }
  }

  onOpenedChanged: {
    if (opened) {
      pinField.text = ""
      if (pinEnabled) pinField.forceActiveFocus()
    }
  }

  // Flat bordered button matching ConfirmDialog's visual language.
  component DialogButton: BorderSurface {
    id: btn

    property string text: ""
    property bool destructive: false
    property bool hovered: btnMouse.containsMouse

    signal clicked()

    width: Style.space(88)
    height: Style.space(34)
    color: hovered
      ? (destructive ? Util.alpha(Color.urgent, 0.22) : Util.alpha(root.foreground, 0.08))
      : "transparent"
    borderSpec: Border.flat(
      destructive ? Util.alpha(Color.urgent, 0.56) : Util.alpha(root.foreground, 0.38),
      Style.normalBorderWidth)
    radius: 0
    opacity: enabled ? 1.0 : 0.5

    Text {
      textFormat: Text.PlainText
      anchors.centerIn: parent
      text: btn.text
      color: btn.destructive ? Color.urgent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (btn.enabled) btn.clicked()
    }
  }
}
