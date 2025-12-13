pragma ComponentBehavior: Bound

import QtQuick
// import Quickshell
import qs.Modules
import qs.Services.Niri
import qs.Components
import qs.Config

FluffModuleBase {
    id: _root

    // ------------------------------------------------------------
    // IMPORTANT FIX:
    // Don't size this module using ListView.contentItem.childrenRect.
    // ListView is virtualized and will only instantiate delegates that
    // are visible (+cache). If your width depends on instantiated delegates
    // you get a feedback loop -> late delegate creation -> "pop-in".
    //
    // We compute width deterministically from (buttonWidth, spacing, count).
    // Additionally, we "lock" the width briefly around sync updates so the
    // view doesn't shrink mid-remove / mid-add, which can also cause delegates
    // to be de-instantiated early or created late.
    // ------------------------------------------------------------

    readonly property real _itemSpacing: 5
    readonly property real _itemStep: _state.buttonWidth + _itemSpacing

    // How many items we *want* to show (target list size)
    readonly property int _desiredCount: (_state.sourceWindows && _state.sourceWindows.length !== undefined) ? _state.sourceWindows.length : 0

    // Width lock count (prevents shrink during transitions)
    property int _widthLockCount: 0

    // The count we actually size the view to right now.
    // - When switching to bigger: desiredCount forces width big BEFORE inserts
    // - When switching to smaller: lockCount keeps width big THROUGH removes
    readonly property int _widthCount: Math.max(_model.count, _desiredCount, _widthLockCount)

    implicitWidth: _widthCount > 0 ? (_widthCount * _itemStep - _itemSpacing) : 0

    QtObject {
        id: _state

        property int activeWsId: Niri.state.getActiveWorkspaceId(_root.output)
        property var sourceWindows: Niri.state.getWindowsForWorkspace(Niri.state.getActiveWorkspaceId(_root.output))

        property real cornerRadius: Theme.shapes.corner.small
        property real buttonWidth: 30

        onSourceWindowsChanged: {
            console.log("Source changed");

            // Lock the width to avoid virtualization churn during add/remove.
            // Keep at least the old size and the incoming target size.
            // _root._widthLockCount = Math.max(_root._widthLockCount, _model.count, _root._desiredCount);

            // If we were about to unlock from a previous update, cancel it.
            // _widthUnlock.stop();
            _root._sync();

            // _updateDebounce.restart();
        }
    }

    Timer {
        id: _updateDebounce
        interval: 10
        running: false
        onTriggered: {
            _root._sync();
            _updateDebounce.stop();

            // Let add/remove transitions finish before allowing the bar to shrink.
            // (Your add/remove duration is 600ms; we add a small cushion.)
            // _widthUnlock.restart()
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

        console.log("Syncing with source", JSON.stringify(source), "Count:", count);

        // 1. Clear empty case fast
        if (count === 0) {
            console.log("Clearing model");
            _model.clear();
            return;
        }

        let i = 0;

        // 2. Iterate through the Desired List (Source)
        while (i < count) {
            const win = source[i];

            // CASE A: We ran out of Model items -> Append new window
            if (i >= _model.count) {
                console.log("Appending new item", JSON.stringify(win));
                _model.append(win);
                i++;
                continue;
            }

            const modelItem = _model.get(i);
            const modelId = modelItem.id;

            // CASE B: Perfect Match -> Update and Move on
            if (modelId === win.id) {
                console.log("Updating item", JSON.stringify(win));
                _model.set(i, win);
                i++;
                continue;
            }

            // CASE C: Mismatch -> Is the CURRENT Model item garbage?
            // Check if the item currently at 'i' exists ANYWHERE in the source.
            // If not, it was closed. Remove it immediately.
            let isGarbage = true;
            for (let k = 0; k < count; k++) {
                if (source[k].id === modelId) {
                    isGarbage = false;
                    break;
                }
            }

            if (isGarbage) {
                // REMOVE: It doesn't exist in source anymore.
                // We remove it at 'i', and DO NOT increment 'i',
                // because the next item in the model has shifted to 'i'.
                console.log("Removing item", JSON.stringify(modelItem));
                _model.remove(i);
                continue;
            }

            // CASE D: The Model item is valid (it belongs later),
            // so the Source item 'win' must be MISSING from this spot.

            // Is 'win' (the one we want) somewhere else in the model?
            let foundIndex = -1;
            for (let k = i + 1; k < _model.count; k++) {
                if (_model.get(k).id === win.id) {
                    foundIndex = k;
                    break;
                }
            }

            if (foundIndex !== -1) {
                // MOVE: We found it later. Bring it here.
                console.log("Moving item", JSON.stringify(modelItem), "to", foundIndex);
                _model.move(foundIndex, i, 1);
                // _model.set(i, win); // Update content if needed
            } else {
                // INSERT: It doesn't exist in the model. Insert it new.
                console.log("Inserting item", JSON.stringify(win));
                _model.insert(i, win);
            }

            // We successfully filled spot 'i', so move to next
            i++;
        }

        // 3. Cleanup: Remove any trailing items that are no longer needed
        while (_model.count > count) {
            console.log("Removing trailing item", JSON.stringify(_model.get(_model.count - 1)));
            _model.remove(_model.count - 1);
        }
    }

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
        spacing: _root._itemSpacing
        anchors.fill: parent

        // Prevent scrolling interaction for a static bar
        interactive: false

        model: _model

        // Deterministic contentWidth (not based on instantiated delegates)
        contentWidth: _model.count > 0 ? (_model.count * _root._itemStep - _root._itemSpacing) : 0

        // Optional: if you ever end up constrained by parent width and still want
        // delegates pre-created, increase cacheBuffer (costs memory)
        // cacheBuffer: 2000

        // --- Animations ---

        // Add (open)
        Transition {
            id: _addTransition
            ParallelAnimation {
                NumberAnimation {
                    property: "scale"
                    from: 0.0
                    to: 1.0
                    duration: _root.animationScale * 600
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: _root.animationScale * 600
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Remove (close)
        Transition {
            id: _removeTransition
            ParallelAnimation {
                NumberAnimation {
                    property: "scale"
                    from: 1.0
                    to: 0.0
                    duration: _root.animationScale * 100
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0
                    duration: _root.animationScale * 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Items displaced because something was inserted/removed elsewhere
        Transition {
            id: _displacedTransition
            NumberAnimation {
                properties: "x"
                duration: _root.animationScale * 250
                easing.type: Easing.OutQuad
            }
        }

        // Explicit moves (_model.move)
        Transition {
            id: _moveTransition
            NumberAnimation {
                properties: "x"
                duration: _root.animationScale * 250
                easing.type: Easing.OutQuad
            }
        }

        add: _addTransition
        remove: _removeTransition
        populate: _addTransition

        displaced: _displacedTransition
        addDisplaced: _displacedTransition
        removeDisplaced: _displacedTransition
        moveDisplaced: _displacedTransition

        move: _moveTransition

        delegate: PillButton {
            id: _delegate

            required property int id
            required property var layout
            required property var title
            required property var app_id

            required property bool is_focused
            required property bool is_floating

            height: _view.height
            width: _state.buttonWidth

            // Ensure a stable default base (helps when items are reused/pooled)
            scale: 1.0
            opacity: 1.0

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
