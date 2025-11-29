pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: _root

    required property var ipc

    // --- 1. Workspace Events ---
    signal workspacesChanged(var workspaces)
    signal workspaceActivated(int id, bool focused)
    signal workspaceActiveWindowChanged(int workspaceId, bool isUndefined, int activeWindowId)
    signal workspaceUrgencyChanged(int id, bool urgent)

    // --- 2. Window Events ---
    signal windowsChanged(var windows)
    signal windowOpenedOrChanged(var window)
    signal windowClosed(int id)
    signal windowFocusChanged(bool isUndefined, int id)
    signal windowFocusTimestampChanged(int id, bool isUndefined, int secs, int nanos)
    signal windowLayoutsChanged(var changes)
    signal windowUrgencyChanged(int id, bool urgent)

    // --- 3. Keyboard & Input ---
    signal keyboardLayoutsChanged(var keyboardLayouts)
    signal keyboardLayoutSwitched(int idx)

    // --- 4. Shell State ---
    signal overviewOpenedOrClosed(bool isOpen)
    signal configLoaded(bool failed)

    // Optional Path handling
    signal screenshotCaptured(bool isUndefined, string path)

    // --- 5. Fallback ---
    signal unknownEventReceived(string type, var data)

    Connections {
        target: _root.ipc
        function onEventReceived(type, data) {
            _handler.handleEvent(type, data);
        }
    }

    QtObject {
        id: _handler

        function handleEvent(type, data) {
            switch (type) {
            case "WorkspacesChanged":
                _root.workspacesChanged(data.workspaces);
                break;
            case "WorkspaceActivated":
                _root.workspaceActivated(data.id, data.focused);
                break;
            case "WorkspaceActiveWindowChanged":
                var winId = data.active_window_id;
                var noWin = (winId === null || winId === undefined);
                _root.workspaceActiveWindowChanged(data.workspace_id, noWin, noWin ? 0 : winId);
                break;
            case "WorkspaceUrgencyChanged":
                _root.workspaceUrgencyChanged(data.id, data.urgent);
                break;
            case "WindowsChanged":
                _root.windowsChanged(data.windows);
                break;
            case "WindowOpenedOrChanged":
                _root.windowOpenedOrChanged(data.window);
                break;
            case "WindowClosed":
                _root.windowClosed(data.id);
                break;
            case "WindowFocusChanged":
                var focusId = data.id;
                var noFocus = (focusId === null || focusId === undefined);
                _root.windowFocusChanged(noFocus, noFocus ? 0 : focusId);
                break;
            case "WindowFocusTimestampChanged":
                var ts = data.focus_timestamp;
                var noTs = (ts === null || ts === undefined);
                _root.windowFocusTimestampChanged(data.id, noTs, noTs ? 0 : ts.secs_since_epoch, noTs ? 0 : ts.nanos);
                break;
            case "WindowLayoutsChanged":
                _root.windowLayoutsChanged(data.changes);
                break;
            case "WindowUrgencyChanged":
                _root.windowUrgencyChanged(data.id, data.urgent);
                break;
            case "KeyboardLayoutsChanged":
                _root.keyboardLayoutsChanged(data.keyboard_layouts);
                break;
            case "KeyboardLayoutSwitched":
                _root.keyboardLayoutSwitched(data.idx);
                break;
            case "OverviewOpenedOrClosed":
                _root.overviewOpenedOrClosed(data.is_open);
                break;
            case "ConfigLoaded":
                _root.configLoaded(data.failed);
                break;
            case "ScreenshotCaptured":
                var path = data.path;
                var noPath = (path === null || path === undefined);
                _root.screenshotCaptured(noPath, noPath ? "" : path);
                break;
            default:
                console.warn(`NiriBus: Unhandled event type: ${type}`);
                _root.unknownEventReceived(type, data);
                break;
            }
        }
    }
}
