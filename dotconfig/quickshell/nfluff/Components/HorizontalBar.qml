pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts as Fuck

import qs.Modules.FluffBar

Item {
    id: _root
    width: Math.max(_layout.implicitWidth + _root.barChildMargin, _root.barWidthMin)
    height: _root.barHeight

    required property string name

    readonly property alias controller: _controller
    readonly property alias mouseArea: _mouse_area
    readonly property alias layout: _layout
    readonly property alias rect: _rect

    required property bool forceClosed
    required property bool autoHideEnabled

    required property double barBorderWidth
    required property double barHeight
    required property double barWidthMin
    required property double barChildMargin
    required property double barBottomLeftRadius
    required property double barBottomRightRadius
    required property double barTopLeftRadius
    required property double barTopRightRadius

    required property color barBackgroundColor
    required property color barBorderColor

    required property double yHidden
    required property double yExpanded

    required property double animationScale

    required property double expansionDuration
    required property double collapseDuration
    required property double widthAnimationDuration

    default property alias children: _layout.children

    FluffBarController {
        id: _controller
        forceClosed: _root.forceClosed
        autoHideEnabled: _root.autoHideEnabled
        mouseArea: _mouse_area
    }
    Rectangle {
        id: _rect
        anchors.fill: parent

        y: _root.yExpanded

        height: _root.barHeight

        bottomLeftRadius: _root.barBottomLeftRadius
        bottomRightRadius: _root.barBottomRightRadius
        topLeftRadius: _root.barTopLeftRadius
        topRightRadius: _root.barTopRightRadius

        color: _root.barBackgroundColor
        border.color: _root.barBorderColor
        border.width: _root.barBorderWidth

        antialiasing: true
        border.pixelAligned: false
        clip: true
        Behavior on width {
            NumberAnimation {
                duration: _root.animationScale * _root.widthAnimationDuration
            }
        }

        MouseArea {
            id: _mouse_area
            anchors.fill: parent
            hoverEnabled: true

            state: _controller.shouldShow ? "expanded" : "collapsed"
            states: [
                State {
                    name: "expanded"
                    PropertyChanges {
                        _root.y: _root.yExpanded
                    }
                },
                State {
                    name: "collapsed"
                    PropertyChanges {
                        _root.y: _root.yHidden
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "expanded"
                    to: "collapsed"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                _top_fluff_controller.preventHiding(_root.name, true);
                            }
                        }
                        PauseAnimation {
                            duration: _root.animationScale * _root.collapseDuration * 3 / 5
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: _root
                                property: "y"
                                duration: _root.animationScale * _root.collapseDuration * 2 / 5
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                _top_fluff_controller.preventHiding(_root.name, false);
                            }
                        }
                    }
                },
                Transition {
                    from: "collapsed"
                    to: "expanded"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                _controller.preventHiding(_root.name, true);
                            }
                        }
                        NumberAnimation {
                            target: _root
                            property: "y"
                            duration: _root.animationScale * _root.expansionDuration
                            easing.type: Easing.OutQuad
                        }
                        ScriptAction {
                            script: {
                                _controller.preventHiding(_root.name, false);
                            }
                        }
                    }
                }
            ]

            Fuck.RowLayout {
                id: _layout
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
        }
    }
}
