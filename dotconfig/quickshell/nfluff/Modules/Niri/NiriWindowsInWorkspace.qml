pragma ComponentBehavior: Bound

import QtQuick
// import Quickshell
import qs.Modules
import qs.Services.Niri
import qs.Components
import qs.Config

FluffModuleBase {
    id: _root

    readonly property real _itemSpacing: 5
    readonly property real _itemStep: _state.buttonWidth + _itemSpacing

    // This is the "incoming" count from Niri (may change before we actually swap)
    readonly property int _desiredCount: (_state.sourceWindows && _state.sourceWindows.length !== undefined) ? _state.sourceWindows.length : 0

    // ---- Workspace-swap state ----
    property int _currentWsId: -1
    property int _pendingWsId: -1
    property var _pendingSource: []
    property bool _workspaceSwapRunning: false

    // While swapping: freeze size to whatever the *current model* is showing
    // (prevents weird “bar grows/shrinks before content changes”).
    readonly property int _widthCount: _workspaceSwapRunning ? _model.count : Math.max(_model.count, _desiredCount)

    implicitWidth: _widthCount > 0 ? (_widthCount * _itemStep - _itemSpacing) : 0

    // When swapping, suppress per-item transitions so we don't see displaced/move weirdness.
    // We will use a whole-list fade instead.
    property bool _suppressListTransitions: false

    readonly property int _swapOutMs: Math.max(0, Math.round(_root.animationScale * 120))
    readonly property int _swapInMs: Math.max(0, Math.round(_root.animationScale * 380))

    function _workspaceIdFromSource(source) {
        // Prefer the workspace_id from the payload (most reliable).
        if (source && source.length > 0 && source[0].workspace_id !== undefined) {
            return source[0].workspace_id;
        }
        // Fallback (needed for empty workspaces).
        return Niri.state.getActiveWorkspaceId(_root.output);
    }

    function _onSourceWindowsChanged() {
        const source = _state.sourceWindows;
        const wsId = _workspaceIdFromSource(source);

        // First time initialization
        if (_currentWsId === -1) {
            _currentWsId = wsId;
            _sync();
            return;
        }

        // Workspace changed => atomic swap
        if (wsId !== _currentWsId) {
            _currentWsId = wsId;
            _beginWorkspaceSwap(wsId, source);
            return;
        }

        // Same workspace:
        // If we're currently swapping (fade out/in), just keep the latest payload.
        // We'll do a final sync when swap ends.
        if (_workspaceSwapRunning) {
            _pendingSource = source;
            _pendingWsId = wsId;
            return;
        }

        // Normal (intra-workspace) diff update
        _sync();
    }

    function _beginWorkspaceSwap(wsId, source) {
        _pendingWsId = wsId;
        _pendingSource = source;

        // If already swapping, don't start another fade; we’ll apply latest pending
        if (_workspaceSwapAnim.running) {
            return;
        }

        _workspaceSwapRunning = true;
        _suppressListTransitions = true;

        _workspaceSwapAnim.restart();
    }

    function _applyPendingSwap() {
        const src = _pendingSource || [];

        // IMPORTANT: do not do incremental removes here.
        // Clear + repopulate while invisible = zero displaced/x-jank.
        _model.clear();
        for (let i = 0; i < src.length; i++) {
            _model.append(src[i]);
        }
    }

    function _finishWorkspaceSwap() {
        _workspaceSwapRunning = false;
        _suppressListTransitions = false;

        // Catch any last-minute updates that arrived during fade-in.
        // (Usually focus updates/timestamps.)
        _sync();
    }

    SequentialAnimation {
        id: _workspaceSwapAnim
        running: false

        // Fade out old list (no model changes while visible)
        ParallelAnimation {
            NumberAnimation {
                target: _swapLayer
                property: "opacity"
                to: 0.0
                duration: _root._swapOutMs
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: _swapLayer
                property: "scale"
                to: 0.98
                duration: _root._swapOutMs
                easing.type: Easing.OutQuad
            }
        }

        // Swap content while fully invisible
        ScriptAction {
            script: _root._applyPendingSwap()
        }

        // Fade in new list
        ParallelAnimation {
            NumberAnimation {
                target: _swapLayer
                property: "opacity"
                to: 1.0
                duration: _root._swapInMs
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: _swapLayer
                property: "scale"
                to: 1.0
                duration: _root._swapInMs
                easing.type: Easing.OutQuad
            }
        }

        ScriptAction {
            script: _root._finishWorkspaceSwap()
        }
    }

    QtObject {
        id: _state

        property int activeWsId: Niri.state.getActiveWorkspaceId(_root.output)
        property var sourceWindows: Niri.state.getWindowsForWorkspace(Niri.state.getActiveWorkspaceId(_root.output))

        property real cornerRadius: Theme.shapes.corner.small
        property real buttonWidth: 30

        onSourceWindowsChanged: {
            console.log("Source changed");
            _root._onSourceWindowsChanged();
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
    }

    function _sync() {
        // If swap animation is running, don't fight it.
        // We will sync at the end in _finishWorkspaceSwap().
        if (_workspaceSwapAnim.running) {
            return;
        }

        const source = _state.sourceWindows;
        const count = source.length;

        console.log("Syncing with source", JSON.stringify(source), "Count:", count);

        if (count === 0) {
            console.log("Clearing model");
            _model.clear();
            return;
        }

        let i = 0;

        while (i < count) {
            const win = source[i];

            if (i >= _model.count) {
                console.log("Appending new item", JSON.stringify(win));
                _model.append(win);
                i++;
                continue;
            }

            const modelItem = _model.get(i);
            const modelId = modelItem.id;

            if (modelId === win.id) {
                console.log("Updating item", JSON.stringify(win));
                _model.set(i, win);
                i++;
                continue;
            }

            let isGarbage = true;
            for (let k = 0; k < count; k++) {
                if (source[k].id === modelId) {
                    isGarbage = false;
                    break;
                }
            }

            if (isGarbage) {
                console.log("Removing item", JSON.stringify(modelItem));
                _model.remove(i);
                continue;
            }

            let foundIndex = -1;
            for (let k = i + 1; k < _model.count; k++) {
                if (_model.get(k).id === win.id) {
                    foundIndex = k;
                    break;
                }
            }

            if (foundIndex !== -1) {
                console.log("Moving item", JSON.stringify(modelItem), "to", foundIndex);
                _model.move(foundIndex, i, 1);
            } else {
                console.log("Inserting item", JSON.stringify(win));
                _model.insert(i, win);
            }

            i++;
        }

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

    Item {
        id: _swapLayer
        anchors.fill: parent
        opacity: 1.0
        scale: 1.0

        ListView {
            id: _view
            orientation: ListView.Horizontal
            spacing: _root._itemSpacing
            anchors.fill: parent
            interactive: false

            model: _model

            contentWidth: _model.count > 0 ? (_model.count * _root._itemStep - _root._itemSpacing) : 0

            // --- Animations ---

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

            Transition {
                id: _displacedTransition
                NumberAnimation {
                    properties: "x"
                    duration: _root.animationScale * 250
                    easing.type: Easing.OutQuad
                }
            }

            Transition {
                id: _moveTransition
                NumberAnimation {
                    properties: "x"
                    duration: _root.animationScale * 250
                    easing.type: Easing.OutQuad
                }
            }

            // Gate transitions during workspace swaps
            add: _root._suppressListTransitions ? null : _addTransition
            remove: _root._suppressListTransitions ? null : _removeTransition
            populate: _root._suppressListTransitions ? null : _addTransition

            displaced: _root._suppressListTransitions ? null : _displacedTransition
            addDisplaced: _root._suppressListTransitions ? null : _displacedTransition
            removeDisplaced: _root._suppressListTransitions ? null : _displacedTransition
            moveDisplaced: _root._suppressListTransitions ? null : _displacedTransition

            move: _root._suppressListTransitions ? null : _moveTransition

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

                // Stable base (important if delegates get reused)
                scale: 1.0
                opacity: 1.0

                backgroundColor: {
                    if (is_floating) {
                        if (is_focused)
                            return Theme.colors.secondary;
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
}
