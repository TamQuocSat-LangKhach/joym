// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Pages
import Fk.RoomElement
import Fk.PhotoElement
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes


GraphicsBox {
  id: root

  property var selectedItem: []
  property var list: []
  ListModel { id : lines }
  //ListModel { id : generals }
  property var generals: []
  property int allNum : 0
  property int restNum : 0
  property int atk : 0
  property int buff : 0
  property int currentX : 0
  property int currentY : 0

  title.text: luatr("joy__tazhen")
  width: 520
  height: 425

  

  Rectangle {
    id: body
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.left : parent.left
    anchors.leftMargin : 20
    width: 300

    color: "#EEEEEE"
    border.color: "#FEF7D6"
    border.width: 3
    radius : 3

    
    Component {
      id: generalDelegate
      
      Item {
        id : generalController
        width : 170
        height : 230
        clip : true
        property int generalIndex
        property var model: ListModel { }
        property string general: model.general
        property int hp: model.hp
        property bool dead: false

        scale: 0.5

        Image {
          id: back
          source: SkinBank.getPhotoBack(model.kingdom)
        }

        Text {
          id: generalName
          x: 5
          y: 28
          font.family: fontLibian.name
          font.pixelSize: 22
          opacity: 0.9
          horizontalAlignment: Text.AlignHCenter
          lineHeight: 18
          lineHeightMode: Text.FixedHeight
          color: "white"
          width: 24
          wrapMode: Text.WrapAnywhere
          text: luatr(general)
        }

        HpBar {
          id: hp
          x: 8
          value: model.hp
          maxValue: model.maxHp
          shieldNum: 0
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 15
        }

        Item {
          width: 138
          height: 222
          visible: false
          id: generalImgItem

          Image {
            id: generalImage
            width: parent.width
            Behavior on width { NumberAnimation { duration: 100 } }
            height: parent.height
            smooth: true
            fillMode: Image.PreserveAspectCrop
            source: model.general === "" ? "" : SkinBank.getGeneralPicture(general)
          }
        }

        Rectangle {
          id: photoMask
          x: 31
          y: 5
          width: 138
          height: 222
          radius: 8
          visible: false
        }

        OpacityMask {
          id: photoMaskEffect
          anchors.fill: photoMask
          source: generalImgItem
          maskSource: photoMask
        }

        Colorize {
          anchors.fill: photoMaskEffect
          source: photoMaskEffect
          saturation: 0
          opacity: dead ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        
        Image {
          id: deadImage
          visible: dead
          source: SkinBank.getRoleDeathPic('hidden');
          anchors.centerIn: photoMask
        }
        

        GlowText {
          id: playerName
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 2
          font.pixelSize: 16
          text: model.screenName

          glow.radius: 8
        }
      }
    }

    Component {
      id: cardDelegate

      Image {
        property string cardName : ""

        source: SkinBank.getCardPicture("tazhen_" + cardName)
        fillMode: Image.PreserveAspectCrop
        scale : 0.9
      }
    }

    Repeater {
      id: itemRepeater
      model: list 
      
      Rectangle {
        id : itemArea
        width : 85
        height : 115
        clip : true
        color : "transparent"

        property bool chosen : false
        property bool selectable : true
        property int posX : (index % 3) + 1
        property int posY : Math.ceil((index + 1) / 3)

        x : 100 * (posX - 1)
        y : 130 * (posY - 1)
        
        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (!chosen && selectable && restNum > 0) {
              if ((currentX === 0) || (Math.abs(currentX - posX) <= 1 && Math.abs(currentY - posY) <= 1)) {
                chosen = true;
                if (currentX !== 0) {
                  lines.append({x1 : 100 * (currentX - 1)+44, y1 : 130 * (currentY - 1)+57,x2 : itemArea.x+44, y2 : itemArea.y+57});
                }
                selectedItem.push(index);
                currentX = posX;
                currentY = posY;
                --restNum;
                if (modelData === "horse") {
                  restNum = restNum + 2;
                } else if (modelData === "slash") {
                  ++atk;
                } else if (modelData === "analeptic") {
                  buff = buff + 2;
                } else {
                  // check general dead here
                  for (var i = 0; i < generals.length; i++) {
                    let general = generals[i];
                    if (general.generalIndex === index && general.hp <= (atk + buff)) {
                      general.dead = true;
                      break;
                    }
                  }
                  buff = 0;
                }
                updateSelectable();
              }
            }
          }
        }

        Component.onCompleted: {
          if (typeof modelData === 'string') {
            cardDelegate.createObject(parent, {x : x-5, y : y-8, cardName : modelData});
            if (modelData == "blank") {
              selectable = false;
            };
          } else {
            const player = leval(
              `(function()
                local player = ClientInstance:getPlayerById(${modelData})
                return {
                  id = player.id,
                  general = player.general,
                  screenName = player.player:getScreenName(),
                  kingdom = player.kingdom,
                  hp = player.hp,
                  maxHp = player.maxHp,
                }
              end)()`
            );
            var newGeneral = generalDelegate.createObject(parent, {x : x-45, y : y-60, model : player, generalIndex : index});
            generals.push(newGeneral)
          }
        }

        
      }
    }
    


    Repeater {
      id: lineRepeater
      model: lines

      Shape {
        anchors.fill : parent
        z : 1

        ShapePath {
          strokeColor: "#EEDDDD"
          strokeWidth: 6
          startX: model.x1
          startY: model.y1
          PathLine { x: model.x2; y: model.y2 }
        }
        
        ShapePath {
          strokeColor: "#EE1426"
          strokeWidth: 4
          startX: model.x1
          startY: model.y1
          PathLine { x: model.x2; y: model.y2 }
        }

      }
    }

  }

  Column {
    id: promptArea
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.right : parent.right
    anchors.rightMargin: 20
    spacing: 20

    Repeater {
      id: promptRepeater
      model: 3

      Rectangle {
        border.color: "#FEF7D6"
        border.width: 2
        width: 180
        height: 65
        color: "#88EEEEEE"
        radius : 5

        GlowText {
          text: luatr("joy__tazhen_prompt" + (index+1)) + " :<br>" + luatr(":joy__tazhen_prompt" + (index+1))
          font.family: fontLibian.name
          font.pixelSize: 20
          font.bold: true
          color: "#FEF7D6"
          glow.color: "#845422"
          glow.spread: 0.5
          anchors.centerIn: parent
        }
      }

    }
  }

  Item {
    id : buttonArea

    MetroButton {
      id : buttonConfirm
      x : 325
      y : 375
      Layout.fillWidth: true
      text: luatr("OK")
      enabled: selectedItem.length

      onClicked: {
        close();
        roomScene.state = "notactive";
        ClientInstance.replyToServer("", JSON.stringify(selectedItem));
      }
    }

    MetroButton {
      id : buttonClear
      x : buttonConfirm.x + 65
      y : buttonConfirm.y
      Layout.fillWidth: true
      text: luatr("Clear All")
      enabled: true

      onClicked: {
        selectedItem = [];
        lines.clear();
        restNum = allNum;
        atk = 0;
        buff = 0;
        currentX = 0;
        currentY = 0;
        for (let i = 0; i < itemRepeater.count; ++i) {
          itemRepeater.itemAt(i).chosen = false;
        }
        for (var i = 0; i < generals.length; i++) {
          generals[i].dead = false;
        }
        updateSelectable();
      }
    }

    MetroButton {
      id : buttonCancel
      x : buttonConfirm.x + 130
      y : buttonConfirm.y
      Layout.fillWidth: true
      text: luatr("Cancel")
      enabled: true

      onClicked: {
        root.close();
        roomScene.state = "notactive";
        ClientInstance.replyToServer("", "");
      }
    }

    GlowText {
      id : stepText
      x : buttonConfirm.x + 25
      y : buttonConfirm.y - 45
      text: luatr("Rest Step") + " : " + restNum.toString()
      font.family: fontLibian.name
      font.pixelSize: 22
      font.bold: true
      color: "#FEF7D6"
      glow.color: "#845422"
      glow.spread: 0.5
    }

    GlowText {
      x : stepText.x
      y : stepText.y - 35
      text: luatr("ATK Num") + " : " + atk.toString() + (buff === 0 ? "" : "(+" + buff.toString() + ")")
      font.family: fontLibian.name
      font.pixelSize: 22
      font.bold: true
      color: "#FE1122"
      glow.color: "#222222"
      glow.spread: 0.5
    }

  }

  function updateSelectable() {
    buttonConfirm.enabled = selectedItem.length;
  }

  function getXYfromIndex(i) {
    return [(i % 3) + 1, Math.ceil((i + 1) / 3)]
  }

  function loadData(data) {
    allNum = data[1];
    restNum = allNum;
    list = data[0];
  }
}
