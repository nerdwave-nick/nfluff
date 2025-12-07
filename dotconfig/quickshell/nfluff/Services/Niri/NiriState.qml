pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: _root

    required property NiriEventBus bus

    readonly property alias windows: _state.windows
    readonly property alias workspaces: _state.workspaces

    readonly property alias focusedWindowId: _state.focusedWindowId
    readonly property alias focusedWorkspaceId: _state.focusedWorkspaceId
    readonly property alias activeWorkspaceMap: _state.activeWorkspaceMap

    readonly property alias keyboardLayoutNames: _state.keyboardLayoutNames
    readonly property alias activeKeyboardLayoutIdx: _state.activeKeyboardLayoutIdx
    readonly property alias isOverviewOpen: _state.isOverviewOpen
    readonly property alias configFailed: _state.configFailed
    readonly property alias lastScreenshotPath: _state.lastScreenshotPath

    function getActiveWorkspaceId(outputName) {
        return _state.activeWorkspaceMap[outputName] ?? -1;
    }

    function getWindowsForWorkspace(workspaceId) {
        if (!_state.windows)
            return [];
        return _state.windows.filter(w => w.workspace_id === workspaceId);
    }

    function getWorkspacesForOutput(outputName) {
        if (!_state.workspaces)
            return [];
        return _state.workspaces.filter(w => w.output === outputName);
    }

    function getWindow(id) {
        if (!_state.windows)
            return null;
        return _state.windows.find(w => w.id === id) || null;
    }

    function getWorkspace(id) {
        if (!_state.workspaces)
            return null;
        return _state.workspaces.find(w => w.id === id) || null;
    }

    // --- Internal State ---

    QtObject {
        id: _state

        property var windows: []
        property var workspaces: []

        property var keyboardLayoutNames: []
        property int activeKeyboardLayoutIdx: -1

        property int focusedWindowId: -1
        property int focusedWorkspaceId: -1
        property var activeWorkspaceMap: ({}) // Map<OutputName, WorkspaceID>

        property bool isOverviewOpen: false
        property bool configFailed: false
        property string lastScreenshotPath: ""

        // this function enforces visual order for the entire shell.
        function _sortWindows(list) {
            return list.sort((a, b) => {
                // group by workspace
                if (a.workspace_id !== b.workspace_id) {
                    return a.workspace_id - b.workspace_id;
                }

                // separate tiling vs floating
                const isFloatA = a.is_floating;
                const isFloatB = b.is_floating;

                if (isFloatA !== isFloatB) {
                    return isFloatA ? 1 : -1;
                }

                // sort tiling windows
                if (!isFloatA) {
                    const posA = a.layout.pos_in_scrolling_layout;
                    const posB = b.layout.pos_in_scrolling_layout;
                    if (posA[0] !== posB[0]) {
                        return posA[0] - posB[0];
                    }
                    return posA[1] - posB[1];
                }

                console.log("comparing floaters a", JSON.stringify(a));
                console.log("comparing floaters b", JSON.stringify(b));
                // sort floating windows
                if (a.layout.tile_pos_in_workspace_view && b.layout.tile_pos_in_workspace_view) {
                    const a_tile_pos = a.layout.tile_pos_in_workspace_view;
                    const b_tile_pos = b.layout.tile_pos_in_workspace_view;
                    // Left -> Right
                    if (a_tile_pos[0] !== b_tile_pos[0]) {
                        console.log("a.x - b.x", a_tile_pos[0], b_tile_pos[0]);
                        return a_tile_pos[0] - b_tile_pos[0];
                    }
                    // Top -> Bottom
                    console.log("a.y - b.y", a_tile_pos[1], b_tile_pos[1]);
                    return a_tile_pos[1] - b_tile_pos[1];
                }

                // fallback to stable id sort
                return a.id - b.id;
            });
        }
        //
        // Workspace Sorting
        function _sortWorkspaces(list) {
            return list.sort((a, b) => {
                // FIX: Use localeCompare for strings. Subtraction returns NaN.
                if (a.output !== b.output) {
                    // Handle null outputs (unlikely but safe)
                    if (!a.output)
                        return 1;
                    if (!b.output)
                        return -1;
                    return a.output.localeCompare(b.output);
                }
                return a.idx - b.idx;
            });
        }
    }

    Connections {
        target: _root.bus

        // WORKSPACES
        // ----------

        function onWorkspacesChanged(ws) {
            let newMap = {};
            let newFocusedId = -1;

            // Single pass to build derived state
            for (let i = 0; i < ws.length; i++) {
                const w = ws[i];
                if (w.output && w.is_active)
                    newMap[w.output] = w.id;
                if (w.is_focused)
                    newFocusedId = w.id;
            }

            _state.activeWorkspaceMap = newMap;
            _state.focusedWorkspaceId = newFocusedId;
            _state.workspaces = _state._sortWorkspaces(ws);
        }

        function onWorkspaceActivated(id, focused) {
            const ws = _state.workspaces.find(w => w.id === id);
            if (!ws)
                return;

            let newMap = Object.assign({}, _state.activeWorkspaceMap);
            newMap[ws.output] = id;
            _state.activeWorkspaceMap = newMap;

            if (focused)
                _state.focusedWorkspaceId = id;

            _state.workspaces = _state.workspaces.map(w => {
                let changed = false;
                let copy = w;

                // is this the new active workspace?
                if (w.id === id) {
                    if (!w.is_active || (focused && !w.is_focused)) {
                        copy = Object.assign({}, w);
                        copy.is_active = true;
                        if (focused)
                            copy.is_focused = true;
                        changed = true;
                    }
                } else
                // is this the old active workspace on the same monitor?
                if (w.output === ws.output && w.is_active) {
                    copy = Object.assign({}, w);
                    copy.is_active = false;
                    copy.is_focused = false;
                    changed = true;
                } else

                // is this the old focused workspace (on a different monitor)?
                if (focused && w.is_focused) {
                    copy = Object.assign({}, w);
                    copy.is_focused = false;
                    changed = true;
                }

                return changed ? copy : w;
            });
        }

        function onWorkspaceActiveWindowChanged(workspaceId, isUndefined, activeWindowId) {
            _state.workspaces = _state.workspaces.map(w => {
                if (w.id === workspaceId) {
                    let copy = Object.assign({}, w);
                    copy.active_window_id = isUndefined ? null : activeWindowId;
                    return copy;
                }
                return w;
            });
        }

        function onWorkspaceUrgencyChanged(id, urgent) {
            _state.workspaces = _state.workspaces.map(w => {
                if (w.id === id) {
                    let copy = Object.assign({}, w);
                    copy.is_urgent = urgent;
                    return copy;
                }
                return w;
            });
        }

        // WINDOWS
        // -------

        function onWindowsChanged(wins) {
            let focusedId = -1;
            for (let i = 0; i < wins.length; i++) {
                if (wins[i].is_focused) {
                    focusedId = wins[i].id;
                    break;
                }
            }
            _state.focusedWindowId = focusedId;
            // Always sort full snapshots
            _state.windows = _state._sortWindows(wins);
        }

        function onWindowOpenedOrChanged(window) {
            console.log("onWindowOpenedOrChanged", JSON.stringify(window));

            const idx = _state.windows.findIndex(w => w.id === window.id);
            let list = _state.windows.slice();

            if (idx !== -1) {
                // check for actual changes
                if (JSON.stringify(list[idx]) === JSON.stringify(window)) {
                    return;
                }
                list[idx] = window;
            } else {
                // INSERT: Append new
                list.push(window);
            }

            if (window.is_focused) {
                for (let i = 0; i < list.length; i++) {
                    list[i].is_focused = list[i].id === window.id;
                }
                _state.focusedWindowId = window.id;
            }
            _state.windows = _state._sortWindows(list);
        }

        function onWindowClosed(id) {
            // FILTER: Preserves relative order, so no expensive re-sort needed!
            _state.windows = _state.windows.filter(w => w.id !== id);

            if (_state.focusedWindowId === id)
                _state.focusedWindowId = -1;
        }

        function onWindowFocusChanged(isUndefined, id) {
            _state.focusedWindowId = isUndefined ? -1 : id;

            // Only update the boolean flags. No sorting needed (focus doesn't change position).
            _state.windows = _state.windows.map(w => {
                // Target
                if (w.id === id) {
                    if (w.is_focused)
                        return w;
                    let copy = Object.assign({}, w);
                    copy.is_focused = true;
                    return copy;
                }
                // Previous Focus
                if (w.is_focused) {
                    let copy = Object.assign({}, w);
                    copy.is_focused = false;
                    return copy;
                }
                return w;
            });
        }

        function onWindowLayoutsChanged(changes) {
            // changes: [[id, layout], [id, layout]]
            let layoutMap = {};
            for (let i = 0; i < changes.length; i++) {
                layoutMap[changes[i][0]] = changes[i][1];
            }

            let newList = _state.windows.map(w => {
                if (layoutMap.hasOwnProperty(w.id)) {
                    console.log("assigning layouts changed", w.id, JSON.stringify(layoutMap[w.id]));
                    let copy = Object.assign({}, w);
                    copy.layout = layoutMap[w.id];
                    return copy;
                }
                return w;
            });

            // Layout changed -> Positions changed -> RE-SORT REQUIRED
            _state.windows = _state._sortWindows(newList);
        }

        function onWindowUrgencyChanged(id, urgent) {
            _state.windows = _state.windows.map(w => {
                if (w.id === id) {
                    let copy = Object.assign({}, w);
                    copy.is_urgent = urgent;
                    return copy;
                }
                return w;
            });
        }

        function onWindowFocusTimestampChanged(id, isUndefined, secs, nanos) {
            if (isUndefined)
                return;
            _state.windows = _state.windows.map(w => {
                if (w.id === id) {
                    let copy = Object.assign({}, w);
                    copy.focus_timestamp = {
                        secs_since_epoch: secs,
                        nanos: nanos
                    };
                    return copy;
                }
                return w;
            });
        }

        // GENERAL STATE
        // -------------

        function onKeyboardLayoutsChanged(layouts) {
            _state.keyboardLayoutNames = layouts.names;
            _state.activeKeyboardLayoutIdx = layouts.current_idx;
        }

        function onKeyboardLayoutSwitched(idx) {
            _state.activeKeyboardLayoutIdx = idx;
        }

        function onOverviewOpenedOrClosed(isOpen) {
            _state.isOverviewOpen = isOpen;
        }

        function onConfigLoaded(failed) {
            _state.configFailed = failed;
        }

        function onScreenshotCaptured(isUndefined, path) {
            if (!isUndefined) {
                _state.lastScreenshotPath = path;
            }
        }
    }
}
