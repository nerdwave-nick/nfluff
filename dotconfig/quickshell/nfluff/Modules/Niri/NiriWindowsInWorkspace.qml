pragma ComponentBehavior: Bound

import QtQuick
// import Quickshell
import qs.Modules
import qs.Services.Niri
import qs.Components
import qs.Config

FluffModuleBase {
    id: _root
    implicitWidth: _view.count === 0 ? _view.contentItem.childrenRect.width : _view.contentWidth



    QtObject {
        id: _state
        property int activeWsId: Niri.state.getActiveWorkspaceId(_root.output)
        property var sourceWindows: Niri.state.getWindowsForWorkspace(_state.activeWsId)
        property real cornerRadius: Theme.shapes.corner.small
        property real buttonWidth: 30
        onSourceWindowsChanged: {
            _root._sync();
        }
    }
    function _scroll(event) {
        if (event.angleDelta.y > 0) {
            Niri.ipc.focus_column_left();
        } else {
            Niri.ipc.focus_column_right();
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: event => _root._scroll(event)
    }

    // --- 2. The Sync Engine ---

    ListModel {
        id: _model
        // Roles: id, title, app_id, is_focused, etc.
    }

    function _sync() {
        const source = _state.sourceWindows;
        const count = source.length;

        if (count === 0) {
            _model.clear();
            return;
        }

        // 1. Trim Bounds
        if (_model.count > count) {
            // Remove items from the end
            for (let i = _model.count - 1; i >= count; i--) {
                _model.remove(i);
            }
        }

        // 2. Update / Move / Insert
        for (let i = 0; i < count; i++) {
            const win = source[i];

            // Is the model item at 'i' the same window?
            if (i < _model.count) {
                const currentId = _model.get(i).id;

                if (currentId === win.id) {
                    // MATCH: Just update data (Title change, focus change)
                    _model.set(i, win);
                } else {
                    // MISMATCH: The window at this position is wrong.
                    // Did our target window move to a later position?
                    let foundIndex = -1;
                    for (let k = i + 1; k < _model.count; k++) {
                        if (_model.get(k).id === win.id) {
                            foundIndex = k;
                            break;
                        }
                    }

                    if (foundIndex !== -1) {
                        // MOVE: It exists later, shift it here.
                        // ListView will animate this visually!
                        _model.move(foundIndex, i, 1);
                        _model.set(i, win);
                    } else {
                        // INSERT: It's a new window
                        _model.insert(i, win);
                    }
                }
            } else {
                // APPEND: New window at the end
                _model.append(win);
            }
        }
    }
    // anchors.horizontalCenter: parent.horizontalCenter
    state: fluffBarController.shouldShow ? "full" : "compact"
    states: [
        State {
            name: "compact"
            PropertyChanges {
                _view.anchors.topMargin: 0
                _view.anchors.bottomMargin: 0
            }
        },
        State {
            name: "full"
            PropertyChanges {
                _view.anchors.topMargin: 8
                _view.anchors.bottomMargin: 8 
            }
        }
    ]
    transitions: [
        Transition {
            from: "compact"
            to: "full"
            SequentialAnimation {
                PauseAnimation {
                    duration: _root.animationScale * 50
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: _view.anchors
                        property: "bottomMargin"
                        duration: _root.animationScale * 150
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: _view.anchors
                        property: "topMargin"
                        duration: _root.animationScale * 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        },
        Transition {
            from: "full"
            to: "compact"
            SequentialAnimation {
                PauseAnimation {
                    duration: _root.animationScale * 300
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: _view.anchors
                        property: "bottomMargin"
                        duration: _root.animationScale * 200
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: _view.anchors
                        property: "topMargin"
                        duration: _root.animationScale * 200
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    ]

    // --- 3. Rendering ---

    ListView {
        id: _view
        orientation: ListView.Horizontal
        spacing: 5
        contentWidth: contentItem.childrenRect.width
        anchors.fill: parent

        // Prevent scrolling interaction for a static bar
        interactive: false

        model: _model

        // --- Animations ---

        // Reordering (e.g. dragging a window left/right)
        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: _root.animationScale * 100
                easing.type: Easing.OutQuad
            }
        }
        addDisplaced: displaced
        removeDisplaced: displaced
        moveDisplaced: displaced
        move: displaced
        populate: add

        // Open
        add: Transition {
            NumberAnimation {
                property: "scale"
                from: 0.0
                to: 1.0
                duration: _root.animationScale * 550
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: _root.animationScale * 550
            }
        }

        // Close
        remove: Transition {
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.0
                duration: _root.animationScale * 550
            }
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0
                duration: _root.animationScale * 550
            }
        }

        delegate: PillButton {
            id: _delegate
            required property int id
            required property var layout
            required property var title
            required property var app_id

            required property bool is_focused
            required property bool is_floating

            
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: _state.buttonWidth
            backgroundColor: {
                if (is_floating) {
                    if (is_focused) {
                        return Theme.colors.secondary;
                    }
                    return Theme.colors.secondaryContainer;
                }
                return is_focused ? Theme.colors.primary : Theme.colors.surfaceVariant;
            }
            hoverBackgroundColor: Qt.darker(Theme.colors.primary, 1.3)
            pressedBackgroundColor: Theme.colors.tertiary
            cornerRadius: _state.cornerRadius
            onLeftClicked: Niri.ipc.focus_window(id)
            onRightClicked: {
                Niri.ipc.focus_window(id);
                Niri.ipc.center_window();
            }
            onMiddleClicked: {
                Niri.ipc.focus_window(id);
                Niri.ipc.close_window();
            }
            onDoubleClicked: {
                Niri.ipc.focus_window(id).then(() => Niri.ipc.toggle_windowed_fullscreen("bread")).then(() => console.log("toggled fullscreen")).catch(console.error);
            }
            onScrolled: event => _root._scroll(event)
        }
    }
}
