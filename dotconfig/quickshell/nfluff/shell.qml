pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts as Fuck
import Quickshell
import qs.Services.Niri
import qs.Modules.Niri
import qs.Modules.FluffBar
import qs.Config
import qs.Components
import qs.Services

ShellRoot {
    id: _root
    Component.onCompleted: Niri.connect = true
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    property double animationScale: 0.5
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: _panel
            required property var modelData
            screen: modelData
            color: "transparent"

            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }
            mask: Region {
                Region {
                    item: _left_rect
                }
                Region {
                    item: _top_center
                }
                Region {
                    item: _top_right
                }
            }

            property bool forceFluffBarClosed: false

            FluffBarController {
                id: _fluffBarLeft
                forceClosed: _panel.forceFluffBarClosed
                autoHideEnabled: Config.autohide
                mouseArea: _mouse_area_left
            }
            Rectangle {
                id: _left_rect
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

                    state: _fluffBarLeft.shouldShow ? "expanded" : "collapsed"
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
                                        target: _left_rect
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
                            output: _panel.screen.name
                            fluffBarController: _fluffBarLeft
                            animationScale: _root.animationScale
                        }
                    }
                }
            }

            HorizontalBar {
                id: _top_center
                anchors.horizontalCenter: parent.horizontalCenter
                name: "top-center"
                yExpanded: -1.5
                yHidden: -1 * 30 + 5
                barBorderWidth: 0.5
                barHeight: 30
                barWidthMin: 150
                barChildMargin: 20
                animationScale: _root.animationScale
                barBottomLeftRadius: Theme.shapes.corner.small
                barBottomRightRadius: Theme.shapes.corner.small
                barTopLeftRadius: Theme.shapes.corner.small
                barTopRightRadius: Theme.shapes.corner.small
                barBackgroundColor: Theme.colors.background
                barBorderColor: Theme.colors.primaryContainer
                forceClosed: _panel.forceFluffBarClosed
                autoHideEnabled: Config.autohide
                expansionDuration: 200
                collapseDuration: 300
                widthAnimationDuration: 200
                children: [
                    NiriWindowsInWorkspace {
                        output: _panel.screen.name
                        fluffBarController: _top_center.controller
                        animationScale: _root.animationScale
                        Fuck.Layout.fillHeight: true
                    }
                ]
            }
            HorizontalBar {
                id: _top_right
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.leftMargin: 80

                name: "top-center"
                yHidden: -5 + _panel.screen.height
                yExpanded: _panel.screen.height  - _top_right.barHeight + 1.5
                barBorderWidth: 0.5
                barHeight: _top_right.children[0].implicitHeight
                // barHeight: 30
                barWidthMin: 150
                barChildMargin: 20
                animationScale: _root.animationScale
                barBottomLeftRadius: Theme.shapes.corner.small
                barBottomRightRadius: Theme.shapes.corner.small
                barTopLeftRadius: Theme.shapes.corner.small
                barTopRightRadius: Theme.shapes.corner.small
                barBackgroundColor: Theme.colors.background
                barBorderColor: Theme.colors.primaryContainer
                forceClosed: _panel.forceFluffBarClosed
                autoHideEnabled: Config.autohide
                expansionDuration: 200
                collapseDuration: 300
                widthAnimationDuration: 200
                children: [
                    Fuck.ColumnLayout {
                        spacing: 8
                        Fuck.RowLayout {
                            spacing: 0
                            Fuck.Layout.alignment: Qt.AlignHCenter
                            Text {
                                text: _top_right.controller.isShowing ? Qt.formatTime(clock.date, "HH:mm") : Utility.getTime(clock.date)
                                color: Theme.colors.primary
                                Fuck.Layout.topMargin: _top_right.controller.isShowing ? 0:-1
                                font.pixelSize: _top_right.controller.isShowing ? 16 : 10
                                font.bold: true
                                font.family: Theme.typography.fontFamily
                            }
                            Text {
                                Fuck.Layout.alignment: Qt.AlignBottom
                                Fuck.Layout.bottomMargin: 2
                                text: Qt.formatTime(clock.date, " ss")
                                color: Theme.colors.primary
                                font.pixelSize: _top_right.controller.isShowing ? 10 : 1
                                font.bold: true
                                font.family: Theme.typography.fontFamily
                            }
                        }
                        Text {
                            text: Qt.formatDate(clock.date, "ddd, dd MMM yyyy")
                            color: Theme.colors.primary
                            font.pixelSize: _top_right.controller.isShowing ? 16 : 12
                            font.family: Theme.typography.fontFamily
                            font.bold: true
                        }
                    }
                ]
            }
        }
    }
}
