pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: rect
    property alias text: label.text
    property color backgroundColor: "#448aff"
    property color hoverBackgroundColor: backgroundColor
    property color pressedBackgroundColor: backgroundColor

    property color borderColor: backgroundColor
    property color hoverBorderColor: hoverBackgroundColor
    property color pressedBorderColor: hoverBackgroundColor

    property color textColor: "white"
    property color hoverTextColor: textColor
    property color pressedTextColor: textColor

    property int cornerRadius: 50 // allows tweaking the roundness externally

    property Transition backgroundColorTransition: Transition {
        ColorAnimation {
            duration: 300
        }
    }

    signal clicked(e: MouseEvent)
    signal leftClicked
    signal rightClicked
    signal middleClicked
    signal doubleClicked
    signal scrolled
    signal entered
    signal exited
    signal pressed(e: MouseEvent)
    signal released(e: MouseEvent)

    width: implicitWidth
    height: implicitHeight
    radius: cornerRadius
    color: backgroundColor
    border.color: borderColor

    implicitHeight: 20
    implicitWidth: label.implicitWidth + 30
    states: [
        State {
            name: "default"
            when: !state.hovered && !state.pressed
            // PropertyChanges {
            //     target: label
            //     color: textColor
            // }
            PropertyChanges {
                rect.border.color: borderColor
                rect.color: backgroundColor
            }
        },
        State {
            name: "focused"
            when: state.hovered && !state.pressed
            // PropertyChanges {
            //     target: label
            //     color: hoverTextColor
            // }
            PropertyChanges {
                rect.border.color: hoverBorderColor
                rect.color: hoverBackgroundColor
            }
        },
        State {
            name: "hovered"
            when: state.hovered && !state.pressed
            // PropertyChanges {
            //     target: label
            //     color: hoverTextColor
            // }
            PropertyChanges {
                rect.border.color: hoverBorderColor
                rect.color: hoverBackgroundColor
            }
        },
        State {
            name: "pressed"
            when: state.pressed
            // PropertyChanges {
            //     target: label
            //     color: pressedTextColor
            // }
            PropertyChanges {
                rect.border.color: pressedBorderColor
                rect.color: pressedBackgroundColor
            }
        }
    ]
    transitions: [
        Transition {
            from: "*"
            to: "default"
            ColorAnimation {
                duration: 100
            }
        },
        Transition {
            from: "default"
            to: "*"
            ColorAnimation {
                duration: 200
            }
        },
        Transition {
            from: "pressed"
            to: "*"
            ColorAnimation {
                duration: 100
            }
        },
        Transition {
            from: "*"
            to: "pressed"
            ColorAnimation {
                duration: 100
            }
        }
    ]

    Text {
        id: label
        anchors.centerIn: parent
        color: parent.textColor
        visible: text
        font.bold: true
    }

    QtObject {
        id: state
        property bool hovered: false
        property bool pressed: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        cursorShape: Qt.PointingHandCursor

        onEntered: () => {
            state.hovered = true;
            parent.entered();
        }
        onExited: () => {
            state.hovered = false;
            parent.exited();
        }

        onPressed: e => {
            state.pressed = true;
            parent.pressed(e);
        }
        onReleased: e => {
            state.pressed = false;
            parent.released(e);
        }

        onWheel: event => {
            parent.scrolled(event);
        }

        onDoubleClicked: {
            parent.doubleClicked();
        }

        onClicked: val => {
            parent.clicked(val);
            switch (val.button) {
            case Qt.LeftButton:
                parent.leftClicked();
                break;
            case Qt.RightButton:
                parent.rightClicked();
                break;
            case Qt.MiddleButton:
                parent.middleClicked();
                break;
            }
        }
    }
}
