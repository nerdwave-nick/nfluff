pragma ComponentBehavior: Bound

import QtQuick
import qs.Modules
import qs.Services.Niri
import qs.Components
import qs.Config

FluffModuleBase {
    id: _root
    implicitHeight: _view.count === 0 ? _view.contentItem.childrenRect.height : _view.contentHeight
    anchors.left: parent.left
    anchors.right: parent.right

    QtObject {
        id: _state
        property var sourceWorkspaces: Niri.state.getWorkspacesForOutput(_root.output)
        property var activeWsIndex: -1
        property real cornerRadius: Theme.shapes.corner.small
        onSourceWorkspacesChanged: {
            _root._sync();
            _state.activeWsIndex = -1;
            for (let i = 0; i < _state.sourceWorkspaces.length; i++) {
                if (_state.sourceWorkspaces[i].id === Niri.state.focusedWorkspaceId) {
                    _state.activeWsIndex = i;
                    break;
                }
            }
        }
    }

    // --- 2. The Sync Engine ---

    ListModel {
        id: _model
    }

    function _sync() {
        const source = _state.sourceWorkspaces.map(x => ({
                    is_focused: x.is_focused,
                    idx: x.idx
                }));
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

    function _scroll(event) {
        if (_state.activeWsIndex === -1)
            return;
        if (event.angleDelta.y > 0) {
            Niri.ipc.focus_workspace_up();
        } else {
            Niri.ipc.focus_workspace_down();
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: event => _root._scroll(event)
    }

    state: fluffBarController.shouldShow ? "full" : "compact"
    states: [
        State {
            name: "compact"
            PropertyChanges {
                _view.anchors.leftMargin: 0
                _view.anchors.rightMargin: 0
            }
        },
        State {
            name: "full"
            PropertyChanges {
                _view.anchors.leftMargin: 5
                _view.anchors.rightMargin: 5
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
                        property: "rightMargin"
                        duration: _root.animationScale * 150
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: _view.anchors
                        property: "leftMargin"
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
                        property: "rightMargin"
                        duration: _root.animationScale * 200
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: _view.anchors
                        property: "leftMargin"
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
        orientation: ListView.Vertical
        spacing: 5
        contentHeight: contentItem.childrenRect.height
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
                from: 0.8
                to: 1.0
                duration: _root.animationScale * 150
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: _root.animationScale * 150
            }
        }

        // Close
        remove: Transition {
            NumberAnimation {
                property: "scale"
                to: 0.8
                duration: _root.animationScale * 150
            }
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: _root.animationScale * 150
            }
        }

        delegate: PillButton {
            id: _delegate
            required property bool is_focused
            required property int idx

            anchors.left: parent.left
            anchors.right: parent.right
            height: 30
            backgroundColor: {
                return is_focused ? Theme.colors.secondary : Theme.colors.surfaceVariant;
            }
            hoverBackgroundColor: Qt.darker(Theme.colors.secondary, 1.3)
            pressedBackgroundColor: Theme.colors.tertiary
            cornerRadius: _state.cornerRadius
            onLeftClicked: Niri.ipc.focus_workspace(idx)
            onScrolled: event => _root._scroll(event)
        }
    }
}
