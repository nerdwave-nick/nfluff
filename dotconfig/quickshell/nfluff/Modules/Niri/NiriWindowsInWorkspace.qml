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

    // ------------------------------------------------------------
    // Workspace swap bookkeeping
    // ------------------------------------------------------------

    // What the model currently contains
    property int _displayedWsId: -1

    // The workspace we want to show now (can change rapidly)
    property int _targetWsId: -1

    // Latest incoming data for the target workspace
    property int _pendingWsId: -1
    property var _pendingSource: []

    // Swap state
    property bool _workspaceSwapRunning: false
    property bool _suppressListTransitions: false

    // Keep width consistent with what is *actually displayed*
    // During swaps we lock it, then update it while invisible.
    property int _lockedWidthCount: 0
    readonly property int _displayCount: _workspaceSwapRunning ? _lockedWidthCount : _model.count
    implicitWidth: _displayCount > 0 ? (_displayCount * _itemStep - _itemSpacing) : 0

    readonly property int _swapOutMs: Math.max(0, Math.round(_root.animationScale * 120))
    readonly property int _swapInMs: Math.max(0, Math.round(_root.animationScale * 140))

    // Coalesce bursts of sourceChanged signals (you get many in logs)
    // This prevents starting multiple swaps in the same frame.
    Timer {
        id: _processTimer
        interval: 0
        repeat: false
        onTriggered: _root._processPending()
    }
    function _scheduleProcess() {
        _processTimer.restart();
    }

    QtObject {
        id: _state

        property int activeWsId: Niri.state.getActiveWorkspaceId(_root.output)
        property var sourceWindows: Niri.state.getWindowsForWorkspace(Niri.state.getActiveWorkspaceId(_root.output))

        property real cornerRadius: Theme.shapes.corner.small
        property real buttonWidth: 30

        onSourceWindowsChanged: {
            _root._scheduleProcess();
        }
        onActiveWsIdChanged: _root._scheduleProcess()
    }

    // ------------------------------------------------------------
    // Interruptible workspace swap (the important part)
    // ------------------------------------------------------------

    function _requestWorkspaceSwap(wsId, source) {
        _pendingWsId = wsId;
        _pendingSource = source;

        if (!_workspaceSwapRunning) {
            _workspaceSwapRunning = true;
            _suppressListTransitions = true;

            // Lock width to what we're currently showing.
            _lockedWidthCount = _model.count;
        }

        // If ANY swap animation is already running, interrupt it immediately.
        // This prevents the "show old workspace for ~0.5s" problem.
        if (_fadeOut.running || _fadeIn.running) {
            _fadeOut.stop();
            _fadeIn.stop();

            // Make the layer invisible NOW so we can safely replace the model.
            _swapLayer.opacity = 0.0;
            _swapLayer.scale = 0.98;

            _applyPendingSwap();
            _fadeIn.restart();
            return;
        }

        // Normal case: fade out, swap, fade in
        if (_swapLayer.opacity > 0.001) {
            _fadeOut.restart();
        } else {
            _applyPendingSwap();
            _fadeIn.restart();
        }
    }

    function _applyPendingSwap() {
        const src = _pendingSource || [];

        _model.clear();
        for (let i = 0; i < src.length; i++) {
            _model.append(src[i]);
        }

        _displayedWsId = _pendingWsId;

        // Update locked width while invisible so layout changes happen "under the fade"
        _lockedWidthCount = _model.count;
    }

    function _finishWorkspaceSwap() {
        _workspaceSwapRunning = false;
        _suppressListTransitions = false;
        _lockedWidthCount = 0;

        // Apply any last focus/timestamp updates that arrived during the animation
        _sync();
    }

    ParallelAnimation {
        id: _fadeOut
        running: false

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

        onFinished: {
            _root._applyPendingSwap();
            _fadeIn.restart();
        }
    }

    ParallelAnimation {
        id: _fadeIn
        running: false

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

        onFinished: _root._finishWorkspaceSwap()
    }

    function _processPending() {
        const wsId = _state.activeWsId;
        const source = _state.sourceWindows || [];

        // First init
        if (_displayedWsId === -1) {
            _displayedWsId = wsId;
            _targetWsId = wsId;
            _pendingWsId = wsId;
            _pendingSource = source;
            _applyPendingSwap();
            _swapLayer.opacity = 1.0;
            _swapLayer.scale = 1.0;
            return;
        }

        // Workspace changed (even rapidly): always request a swap
        if (wsId !== _targetWsId) {
            _targetWsId = wsId;
            _requestWorkspaceSwap(wsId, source);
            return;
        }

        // Same workspace:
        // If swap is running, keep the newest source so the moment we’re invisible
        // we can apply it immediately (and interruptions work cleanly).
        if (_workspaceSwapRunning) {
            _pendingWsId = wsId;
            _pendingSource = source;

            // If we are currently fully invisible and not fading out, apply immediately.
            if (_swapLayer.opacity <= 0.001 && !_fadeOut.running) {
                _applyPendingSwap();
            }
            return;
        }

        // Intra-workspace updates: diff sync normally
        _sync();
    }

    // ------------------------------------------------------------

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

    // --- Sync engine ---

    ListModel {
        id: _model
    }

    function _sync() {
        // Don't diff while swapping
        if (_workspaceSwapRunning || _fadeOut.running || _fadeIn.running) {
            return;
        }

        const source = _state.sourceWindows;
        const count = source.length;

        if (count === 0) {
            _model.clear();
            return;
        }

        let i = 0;
        while (i < count) {
            const win = source[i];

            if (i >= _model.count) {
                _model.append(win);
                i++;
                continue;
            }

            const modelItem = _model.get(i);
            const modelId = modelItem.id;

            if (modelId === win.id) {
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
                _model.move(foundIndex, i, 1);
            } else {
                _model.insert(i, win);
            }

            i++;
        }

        while (_model.count > count) {
            _model.remove(_model.count - 1);
        }
    }

    // --- Your compact/full transitions unchanged ---

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

    // --- Rendering ---

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

            // --- Transitions (suppressed during workspace swaps) ---

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
