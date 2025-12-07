pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services.Niri
import qs.Modules.Niri
import qs.Modules.FluffBar
import qs.Config

ShellRoot {
    id: _root
    Component.onCompleted: Niri.connect = true
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    property double animationScale: 0.5
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: _window_left
            required property var modelData
            screen: modelData
            color: "transparent"
            property double screenHeight: screen.height
            exclusiveZone: _rectLeft.width
            exclusionMode: Config.autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
            anchors {
                top: true
                left: true
                bottom: true
            }
            mask: Region {
                item: _rectLeft
            }

            property bool forceFluffBarClosed: false
            FluffBarController {
                id: _fluffBarLeft
                forceClosed: _window_left.forceFluffBarClosed
                autoHideEnabled: Config.autohide
                mouseArea: _mouse_area_left
            }
            Rectangle {
                id: _rectLeft
                anchors.verticalCenter: parent.verticalCenter
                x: -1.5
                width: 30
                height: _layout.implicitHeight + _layout.children.length * 20
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

                    state: _fluffBarLeft.shouldShow ? "expanded" : "collapsed"
                    states: [
                        State {
                            name: "expanded"
                            PropertyChanges {
                                _rectLeft.x: -1.5
                            }
                        },
                        State {
                            name: "collapsed"
                            PropertyChanges {
                                _rectLeft.x: -1 * _rectLeft.width + 5
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
                                        target: _rectLeft
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
                                    target: _rectLeft
                                    property: "x"
                                    duration: _root.animationScale * 200
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    ]

                    ColumnLayout {
                        id: _layout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 10
                        NiriWorkspaces {
                            output: _window_left.screen.name
                            fluffBarController: _fluffBarLeft
                            animationScale: _root.animationScale
                        }
                    }
                }
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: _window_top
            required property var modelData
            screen: modelData
            color: "transparent"
            property double screenWidth: screen.width
            exclusiveZone: _rectTop.height
            implicitHeight: screen.height
            exclusionMode: Config.autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
            anchors {
                top: true
                left: true
                right: true
            }
            mask: Region {
                item: _rectTop
            }

            property bool forceFluffBarClosed: false

            FluffBarController {
                id: _fluffBarTop
                forceClosed: _window_top.forceFluffBarClosed
                autoHideEnabled: Config.autohide
                mouseArea: _mouse_area_top
            }
            Rectangle {
                id: _rectTop
                anchors.horizontalCenter: parent.horizontalCenter
                y: -1.5
                height: 30
                width: _window_top.screenWidth / 1.618
                bottomLeftRadius: Theme.shapes.corner.large
                bottomRightRadius: Theme.shapes.corner.large
                color: Theme.colors.background
                border.width: 0.5
                antialiasing: true
                border.pixelAligned: false
                border.color: Theme.colors.primaryContainer
                clip: true

                property double maxCollapsedWidth: 1280
                property double minCollapsedWidth: 640
                property double clampedCollapsedWidth: Math.min(maxCollapsedWidth, Math.max(_window_top.screenWidth / 1.718, minCollapsedWidth))

                property double maxExpandedWidth: 1280
                property double minExpandedWidth: 640
                property double clampedExpandedWidth: Math.min(maxExpandedWidth, Math.max(_window_top.screenWidth / 1.618, minExpandedWidth))

                MouseArea {
                    id: _mouse_area_top
                    anchors.fill: parent
                    hoverEnabled: true

                    state: _fluffBarTop.shouldShow ? "expanded" : "collapsed"
                    states: [
                        State {
                            name: "expanded"
                            PropertyChanges {
                                _rectTop.y: -1.5
                                _rectTop.width: _rectTop.clampedExpandedWidth
                            }
                        },
                        State {
                            name: "collapsed"
                            PropertyChanges {
                                _rectTop.y: -1 * _rectTop.height + 5
                                _rectTop.width: _rectTop.clampedCollapsedWidth
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
                                        _fluffBarTop.preventHiding("rect-collapse-anim", true);
                                    }
                                }
                                PauseAnimation {
                                    duration: _root.animationScale * 300
                                }
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: _rectTop
                                        property: "y"
                                        duration: _root.animationScale * 200
                                        easing.type: Easing.InQuad
                                    }
                                    NumberAnimation {
                                        target: _rectTop
                                        property: "width"
                                        duration: _root.animationScale * 200
                                        easing.type: Easing.InQuad
                                    }
                                }
                                ScriptAction {
                                    script: {
                                        _fluffBarTop.preventHiding("rect-collapse-anim", false);
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
                                        _fluffBarTop.preventHiding(200);
                                    }
                                }
                                NumberAnimation {
                                    target: _rectTop
                                    property: "y"
                                    duration: _root.animationScale * 200
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    target: _rectTop
                                    property: "width"
                                    duration: _root.animationScale * 200
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    ]

                    // RowLayout {
                    //     anchors.left: parent.left
                    //     anchors.leftMargin: Theme.spacing.lg
                    //     anchors.verticalCenter: parent.verticalCenter
                    //     Repeater {
                    //         id: workspaces
                    //         model: Niri.state.workspaces
                    //         Text {
                    //             required property bool is_focused
                    //             color: Theme.colors.primary
                    //             font.pixelSize: Theme.typography.medium.size
                    //             font.weight: Theme.typography.medium.weight
                    //             font.bold: is_focused
                    //             font.letterSpacing: 8
                    //             text: is_focused ? "⊙" : "⋅"
                    //         }
                    //     }
                    // }
                    NiriWindowsInWorkspace {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        output: _window_top.screen.name
                        fluffBarController: _fluffBarTop
                        animationScale: _root.animationScale
                    }
                    // RowLayout {
                    //     id: layout
                    //     anchors.right: parent.right
                    //     anchors.rightMargin: Theme.spacing.lg
                    //     anchors.verticalCenter: parent.verticalCenter
                    //     Text {
                    //         font.family: Theme.typography.fontFamily
                    //         font.pixelSize: Theme.typography.medium.size
                    //         font.weight: Theme.typography.medium.weight

                    //         color: Theme.colors.on.background
                    //         text: Qt.formatDateTime(clock.date, "hh:mm")
                    //     }
                    // }
                }
            }
        }
    }
}
