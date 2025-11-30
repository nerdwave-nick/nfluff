pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services.Niri
import qs.Modules.Niri
import qs.Config

ShellRoot {
    Component.onCompleted: Niri.connect = true
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            color: "transparent"
            property double screenWidth: screen.width
            exclusionMode: Config.autohide ? ExclusionMode.Ignore : ExclusionMode.Normal
            exclusiveZone: _rect.height
            implicitHeight: screen.height
            Component.onCompleted: {
            }
            Item {
                id: _panel_states
                visible: false
                states: [
                    State {
                        name: "autohide"
                        when: Config.autohide
                        PropertyChanges {
                            window.exclusionMode: ExclusionMode.Ignore
                        }
                    },
                    State {
                        name: "static"
                        when: !Config.autohide
                        PropertyChanges {
                            window.exclusionMode: ExclusionMode.Normal
                        }
                    }
                ]
            }
            anchors {
                top: true
                left: true
                right: true
            }
            mask: Region {
                item: _rect
            }

            Rectangle {
                id: _rect
                anchors.horizontalCenter: parent.horizontalCenter
                y: -1.5
                height: 50
                width: window.screenWidth / 1.618
                bottomLeftRadius: Theme.shapes.corner.large
                bottomRightRadius: Theme.shapes.corner.large
                color: Theme.colors.background
                border.width: 0.5
                antialiasing: true
                border.pixelAligned: false
                border.color: Theme.colors.primaryContainer
                clip: true
                state: "default"
                function flash() {
                    if (_rect.state === "flash")
                        return;
                    _rect.state = "flash";
                    if (!_window_states.isExpanded) {
                        _window_states.overrideState = "flash";
                    }
                }
                Connections {
                    target: Niri.bus
                    function onWindowOpenedOrChanged(window) {
                        if (!window.is_focused)
                            return;
                        _rect.flash();
                    }
                    function onWindowFocusChanged(isUndefined, id) {
                        if (isUndefined)
                            return;
                        _rect.flash();
                    }
                    function onWindowLayoutsChanged(changes) {
                        if (changes.length === 0)
                            return;
                        _rect.flash();
                    }
                }
                states: [
                    State {
                        name: "default"
                        PropertyChanges {
                            _rect.color: Theme.colors.background
                        }
                    },
                    State {
                        name: "flash"
                        PropertyChanges {
                            _rect.color: Qt.alpha(Theme.colors.background, 0.5)
                        }
                    }
                ]
                transitions: [
                    Transition {
                        from: "default"
                        to: "flash"
                        SequentialAnimation {
                            ColorAnimation {
                                duration: 50
                                easing.type: Easing.OutQuad
                            }
                            ScriptAction {
                                script: {
                                    _rect.state = "default";
                                }
                            }
                        }
                    },
                    Transition {
                        from: "flash"
                        to: "default"
                        SequentialAnimation {
                            PauseAnimation {
                                duration: 200
                            }
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.InQuad
                            }
                        }
                    }
                ]
                MouseArea {
                    id: _mouse_area
                    anchors.fill: parent
                    hoverEnabled: true
                    Item {
                        id: _window_states
                        property bool isExpanded: (!Config.autohide) || _mouse_area.containsMouse

                        property double maxCollapsedWidth: 1280
                        property double minCollapsedWidth: 640
                        property double clampedCollapsedWidth: Math.min(maxCollapsedWidth, Math.max(window.screenWidth / 1.718, minCollapsedWidth))

                        property double maxExpandedWidth: 1280
                        property double minExpandedWidth: 640
                        property double clampedExpandedWidth: Math.min(maxExpandedWidth, Math.max(window.screenWidth / 1.618, minExpandedWidth))

                        property string overrideState: ""
                        state: overrideState !== "" ? overrideState : _window_states.isExpanded ? "expanded" : "collapsed"
                        states: [
                            State {
                                name: "expanded"
                                PropertyChanges {
                                    _rect.y: -1.5
                                    _rect.width: _window_states.clampedExpandedWidth
                                }
                            },
                            State {
                                name: "collapsed"
                                PropertyChanges {
                                    _rect.y: -1 * _rect.height + 5
                                    _rect.width: _window_states.clampedCollapsedWidth
                                }
                            },
                            State {
                                name: "flash"
                                PropertyChanges {
                                    _rect.y: -1.5
                                    _rect.width: _window_states.clampedExpandedWidth
                                }
                            }
                        ]
                        transitions: [
                            Transition {
                                from: "*"
                                to: "flash"
                                SequentialAnimation {
                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: _rect
                                            property: "y"
                                            duration: 50
                                            easing.type: Easing.OutQuad
                                        }
                                        NumberAnimation {
                                            target: _rect
                                            property: "width"
                                            duration: 50
                                            easing.type: Easing.OutQuad
                                        }
                                    }

                                    ScriptAction {
                                        script: {
                                            _window_states.overrideState = "";
                                        }
                                    }
                                }
                            },
                            Transition {
                                from: "flash"
                                to: "*"
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: 200
                                    }
                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: _rect
                                            property: "y"
                                            duration: 150
                                            easing.type: Easing.OutQuad
                                        }
                                        NumberAnimation {
                                            target: _rect
                                            property: "width"
                                            duration: 150
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                            },
                            Transition {
                                from: "expanded"
                                to: "collapsed"
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: 300
                                    }
                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: _rect
                                            property: "y"
                                            duration: 200
                                            easing.type: Easing.InQuad
                                        }
                                        NumberAnimation {
                                            target: _rect
                                            property: "width"
                                            duration: 200
                                            easing.type: Easing.InQuad
                                        }
                                    }
                                }
                            },
                            Transition {
                                from: "collapsed"
                                to: "expanded"
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: _rect
                                        property: "y"
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: _rect
                                        property: "width"
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        ]
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.lg
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            id: workspaces
                            model: Niri.state.workspaces
                            Text {
                                required property bool is_focused
                                color: Theme.colors.primary
                                font.pixelSize: Theme.typography.medium.size
                                font.weight: Theme.typography.medium.weight
                                font.bold: is_focused
                                font.letterSpacing: 8
                                text: is_focused ? "⊙" : "⋅"
                            }
                        }
                    }
                    NiriWindowsInWorkspace {
                        anchors.centerIn: parent
                        output: window.screen.name
                    }
                    RowLayout {
                        id: layout
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacing.lg
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            font.family: Theme.typography.fontFamily
                            font.pixelSize: Theme.typography.medium.size
                            font.weight: Theme.typography.medium.weight

                            color: Theme.colors.on.background
                            text: Qt.formatDateTime(clock.date, "hh:mm")
                        }
                    }
                }
            }
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
        }
    }
}
