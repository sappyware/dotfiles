import QtQuick

Row {
  id: root
  spacing: 10
  MdButton {
    visible: sddm.canSuspend
    width: 44; height: 44; shape: "circle"; pressedShape: "cookie"
    bg: Theme.s.secondaryContainer; fg: Theme.s.onSecondaryContainer; icon: "moon"; iconSize: 22
    onClicked: sddm.suspend()
  }
  MdButton {
    visible: sddm.canReboot
    width: 44; height: 44; shape: "circle"; pressedShape: "cookie"
    bg: Theme.s.secondaryContainer; fg: Theme.s.onSecondaryContainer; icon: "restart"; iconSize: 22
    onClicked: sddm.reboot()
  }
  MdButton {
    visible: sddm.canPowerOff
    width: 44; height: 44; shape: "circle"; pressedShape: "cookie"
    bg: Theme.s.errorContainer; fg: Theme.s.onErrorContainer; icon: "power"; iconSize: 22
    onClicked: sddm.powerOff()
  }
}
