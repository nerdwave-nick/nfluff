pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts as Fuck

import qs.Modules

import qs.Config

FluffModuleBase {
    id: _root
    Rectangle {
        id: _rect
        anchors.verticalCenter: parent.verticalCenter
        x: -1.5
        width: 30
        height: _left_layout.implicitHeight + 20
        topRightRadius: Theme.shapes.corner.small
        bottomRightRadius: Theme.shapes.corner.small
        color: Theme.colors.background
        border.width: 0.5
        antialiasing: true
        border.pixelAligned: false
        border.color: Theme.colors.primaryContainer
        clip: true

        MouseArea {
            id: _mouse_area_left
            hoverEnabled: true
            anchors.fill: parent

            state: _root.fluffBarController.shouldShow ? "expanded" : "collapsed"
            states: [
                State {
                    name: "expanded"
                    PropertyChanges {
                        _left_rect.x: -1.5
                    }
                },
                State {
                    name: "collapsed"
                    PropertyChanges {
                        _left_rect.x: -1 * _left_rect.width + 5
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
                                _fluffBarLeft.preventHiding("rect-collapse-anim", true);
                            }
                        }
                        PauseAnimation {
                            duration: _root.animationScale * 300
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: _rect
                                property: "x"
                                duration: _root.animationScale * 200
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                _fluffBarLeft.preventHiding("rect-collapse-anim", false);
                            }
                        }
                    }
                },
                Transition {
                    from: "collapsed"
                    to: "expanded"
                    ParallelAnimation {
                        ScriptAction {
                            script: {
                                _fluffBarLeft.preventHiding(200);
                            }
                        }
                        NumberAnimation {
                            target: _left_rect
                            property: "x"
                            duration: _root.animationScale * 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            ]

            Fuck.ColumnLayout {
                id: _left_layout
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 10
                NiriWorkspaces {
                    Fuck.Layout.fillWidth: true
                    output: _panel_left.screen.name
                    fluffBarController: _fluffBarLeft
                    animationScale: _root.animationScale
                }
            }
        }
    }
}
