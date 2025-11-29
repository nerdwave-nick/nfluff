pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Item {
    id: _root
    property alias connect: _state.connect
    readonly property alias readConnected: _readSocket.isConnected
    readonly property alias writeConnected: _writeSocket.isConnected

    property alias socketPath: _state.socketPath

    signal messageReceived(var message)
    signal eventReceived(string eventName, var eventData)

    QtObject {
        id: _state

        property bool connect: false
        property string socketPath: Quickshell.env("NIRI_SOCKET")
    }

    NiriSocket {
        id: _readSocket
        path: _state.socketPath
        connect: _state.connect
        onMessageReceived: msg => _root.messageReceived(msg)
        onEventReceived: (type, data) => _root.eventReceived(type, data)
        onIsConnectedChanged: {
            if (_readSocket.isConnected) {
                _readSocket.sendString('"EventStream"');
            }
        }
    }

    NiriSocket {
        id: _writeSocket
        path: _state.socketPath
        connect: _state.connect
    }

    // =========================================================================
    // SYSTEM / SHELL
    // =========================================================================

    function quit(skipConfirmation = false) {
        _writeSocket.sendAction("Quit", {
            skip_confirmation: skipConfirmation
        });
    }

    function load_config_file() {
        _writeSocket.sendAction("LoadConfigFile", {});
    }

    function power_off_monitors() {
        _writeSocket.sendAction("PowerOffMonitors", {});
    }
    function power_on_monitors() {
        _writeSocket.sendAction("PowerOnMonitors", {});
    }

    // command: Vec<String> e.g. ["alacritty", "-e", "htop"]
    function spawn(command) {
        _writeSocket.sendAction("Spawn", {
            command: command
        });
    }

    // command: String e.g. "alacritty -e htop"
    function spawn_sh(command) {
        _writeSocket.sendAction("SpawnSh", {
            command: command
        });
    }

    function do_screen_transition(delayMs = null) {
        _writeSocket.sendAction("DoScreenTransition", {
            delay_ms: delayMs
        });
    }

    function show_hotkey_overlay() {
        _writeSocket.sendAction("ShowHotkeyOverlay", {});
    }

    function toggle_debug_tint() {
        _writeSocket.sendAction("ToggleDebugTint", {});
    }
    function debug_toggle_opaque_regions() {
        _writeSocket.sendAction("DebugToggleOpaqueRegions", {});
    }
    function debug_toggle_damage() {
        _writeSocket.sendAction("DebugToggleDamage", {});
    }

    function toggle_keyboard_shortcuts_inhibit() {
        _writeSocket.sendAction("ToggleKeyboardShortcutsInhibit", {});
    }

    // SwitchLayout { layout: LayoutSwitchTarget }
    // direction: "Next" | "Prev"
    function switch_layout(direction) {
        let layoutArg = {};
        layoutArg[direction] = {};
        _writeSocket.sendAction("SwitchLayout", {
            layout: layoutArg
        });
    }

    // =========================================================================
    // SCREENSHOT / CAST
    // =========================================================================

    function screenshot(showPointer = false) {
        _writeSocket.sendAction("Screenshot", {
            show_pointer: showPointer
        });
    }
    function screenshot_screen(writeToDisk = true, showPointer = false) {
        _writeSocket.sendAction("ScreenshotScreen", {
            write_to_disk: writeToDisk,
            show_pointer: showPointer
        });
    }
    function screenshot_window(id = null, writeToDisk = true) {
        _writeSocket.sendAction("ScreenshotWindow", {
            id: id,
            write_to_disk: writeToDisk
        });
    }

    function set_dynamic_cast_window(id = null) {
        _writeSocket.sendAction("SetDynamicCastWindow", {
            id: id
        });
    }

    // Rust: output: Option<String>
    function set_dynamic_cast_monitor(outputName = null) {
        _writeSocket.sendAction("SetDynamicCastMonitor", {
            output: outputName
        });
    }

    function clear_dynamic_cast_target() {
        _writeSocket.sendAction("ClearDynamicCastTarget", {});
    }

    // =========================================================================
    // OVERVIEW
    // =========================================================================

    function toggle_overview() {
        _writeSocket.sendAction("ToggleOverview", {});
    }
    function open_overview() {
        _writeSocket.sendAction("OpenOverview", {});
    }
    function close_overview() {
        _writeSocket.sendAction("CloseOverview", {});
    }

    // =========================================================================
    // WINDOW FOCUS
    // =========================================================================

    // Rust: id: u64 (Mandatory)
    function focus_window(id) {
        if (id === undefined || id === null)
            console.warn("NiriIPC: focus_window requires ID");
        _writeSocket.sendAction("FocusWindow", {
            id: id
        });
    }

    function focus_window_in_column(index) {
        _writeSocket.sendAction("FocusWindowInColumn", {
            index: index
        });
    }
    function focus_window_previous() {
        _writeSocket.sendAction("FocusWindowPrevious", {});
    }

    function focus_window_up() {
        _writeSocket.sendAction("FocusWindowUp", {});
    }
    function focus_window_down() {
        _writeSocket.sendAction("FocusWindowDown", {});
    }
    function focus_window_top() {
        _writeSocket.sendAction("FocusWindowTop", {});
    }
    function focus_window_bottom() {
        _writeSocket.sendAction("FocusWindowBottom", {});
    }

    // Compound Focus Actions
    function focus_window_or_monitor_up() {
        _writeSocket.sendAction("FocusWindowOrMonitorUp", {});
    }
    function focus_window_or_monitor_down() {
        _writeSocket.sendAction("FocusWindowOrMonitorDown", {});
    }
    function focus_window_or_workspace_up() {
        _writeSocket.sendAction("FocusWindowOrWorkspaceUp", {});
    }
    function focus_window_or_workspace_down() {
        _writeSocket.sendAction("FocusWindowOrWorkspaceDown", {});
    }

    function focus_window_down_or_column_left() {
        _writeSocket.sendAction("FocusWindowDownOrColumnLeft", {});
    }
    function focus_window_down_or_column_right() {
        _writeSocket.sendAction("FocusWindowDownOrColumnRight", {});
    }
    function focus_window_up_or_column_left() {
        _writeSocket.sendAction("FocusWindowUpOrColumnLeft", {});
    }
    function focus_window_up_or_column_right() {
        _writeSocket.sendAction("FocusWindowUpOrColumnRight", {});
    }

    function focus_window_down_or_top() {
        _writeSocket.sendAction("FocusWindowDownOrTop", {});
    }
    function focus_window_up_or_bottom() {
        _writeSocket.sendAction("FocusWindowUpOrBottom", {});
    }

    // =========================================================================
    // WINDOW MOVEMENT
    // =========================================================================

    function move_window_up() {
        _writeSocket.sendAction("MoveWindowUp", {});
    }
    function move_window_down() {
        _writeSocket.sendAction("MoveWindowDown", {});
    }
    function move_window_down_or_to_workspace_down() {
        _writeSocket.sendAction("MoveWindowDownOrToWorkspaceDown", {});
    }
    function move_window_up_or_to_workspace_up() {
        _writeSocket.sendAction("MoveWindowUpOrToWorkspaceUp", {});
    }

    // Rust: reference: WorkspaceReferenceArg, window_id: Option<u64>
    function move_window_to_workspace(indexOrName, windowId = null, focus = true) {
        let ref = (typeof indexOrName === "number") ? {
            "Index": indexOrName
        } : {
            "Name": indexOrName.toString()
        };
        _writeSocket.sendAction("MoveWindowToWorkspace", {
            window_id: windowId,
            reference: ref,
            focus: focus
        });
    }

    function move_window_to_workspace_down(focus = true) {
        _writeSocket.sendAction("MoveWindowToWorkspaceDown", {
            focus: focus
        });
    }
    function move_window_to_workspace_up(focus = true) {
        _writeSocket.sendAction("MoveWindowToWorkspaceUp", {
            focus: focus
        });
    }

    // Rust: output: String (NOT ReferenceArg), id: Option<u64>
    function move_window_to_monitor(outputName, windowId = null) {
        _writeSocket.sendAction("MoveWindowToMonitor", {
            id: windowId,
            output: outputName
        });
    }

    function move_window_to_monitor_left() {
        _writeSocket.sendAction("MoveWindowToMonitorLeft", {});
    }
    function move_window_to_monitor_right() {
        _writeSocket.sendAction("MoveWindowToMonitorRight", {});
    }
    function move_window_to_monitor_down() {
        _writeSocket.sendAction("MoveWindowToMonitorDown", {});
    }
    function move_window_to_monitor_up() {
        _writeSocket.sendAction("MoveWindowToMonitorUp", {});
    }
    function move_window_to_monitor_previous() {
        _writeSocket.sendAction("MoveWindowToMonitorPrevious", {});
    }
    function move_window_to_monitor_next() {
        _writeSocket.sendAction("MoveWindowToMonitorNext", {});
    }

    function swap_window_left() {
        _writeSocket.sendAction("SwapWindowLeft", {});
    }
    function swap_window_right() {
        _writeSocket.sendAction("SwapWindowRight", {});
    }

    // =========================================================================
    // WINDOW STATE / SIZE
    // =========================================================================

    function close_window(id = null) {
        _writeSocket.sendAction("CloseWindow", {
            id: id
        });
    }
    function center_window(id = null) {
        _writeSocket.sendAction("CenterWindow", {
            id: id
        });
    }
    function fullscreen_window(id = null) {
        _writeSocket.sendAction("FullscreenWindow", {
            id: id
        });
    }
    function toggle_windowed_fullscreen(id = null) {
        _writeSocket.sendAction("ToggleWindowedFullscreen", {
            id: id
        });
    }

    // SetWindowWidth { id: Option<u64>, change: SizeChange }
    function set_window_width_pixels(pixels, id = null) {
        _writeSocket.sendAction("SetWindowWidth", {
            id: id,
            change: {
                "SetFixed": pixels
            }
        });
    }
    function set_window_width_percent(percent, id = null) {
        _writeSocket.sendAction("SetWindowWidth", {
            id: id,
            change: {
                "SetProportion": percent
            }
        });
    }

    function set_window_height_pixels(pixels, id = null) {
        _writeSocket.sendAction("SetWindowHeight", {
            id: id,
            change: {
                "SetFixed": pixels
            }
        });
    }
    function set_window_height_percent(percent, id = null) {
        _writeSocket.sendAction("SetWindowHeight", {
            id: id,
            change: {
                "SetProportion": percent
            }
        });
    }
    function reset_window_height(id = null) {
        _writeSocket.sendAction("ResetWindowHeight", {
            id: id
        });
    }

    function switch_preset_window_width(id = null) {
        _writeSocket.sendAction("SwitchPresetWindowWidth", {
            id: id
        });
    }
    function switch_preset_window_width_back(id = null) {
        _writeSocket.sendAction("SwitchPresetWindowWidthBack", {
            id: id
        });
    }
    function switch_preset_window_height(id = null) {
        _writeSocket.sendAction("SwitchPresetWindowHeight", {
            id: id
        });
    }
    function switch_preset_window_height_back(id = null) {
        _writeSocket.sendAction("SwitchPresetWindowHeightBack", {
            id: id
        });
    }

    function consume_or_expel_window_left(id = null) {
        _writeSocket.sendAction("ConsumeOrExpelWindowLeft", {
            id: id
        });
    }
    function consume_or_expel_window_right(id = null) {
        _writeSocket.sendAction("ConsumeOrExpelWindowRight", {
            id: id
        });
    }
    function consume_window_into_column() {
        _writeSocket.sendAction("ConsumeWindowIntoColumn", {});
    }
    function expel_window_from_column() {
        _writeSocket.sendAction("ExpelWindowFromColumn", {});
    }

    function toggle_window_rule_opacity(id = null) {
        _writeSocket.sendAction("ToggleWindowRuleOpacity", {
            id: id
        });
    }

    // =========================================================================
    // FLOATING / TILING
    // =========================================================================

    function toggle_window_floating(id = null) {
        _writeSocket.sendAction("ToggleWindowFloating", {
            id: id
        });
    }
    function move_window_to_floating(id = null) {
        _writeSocket.sendAction("MoveWindowToFloating", {
            id: id
        });
    }
    function move_window_to_tiling(id = null) {
        _writeSocket.sendAction("MoveWindowToTiling", {
            id: id
        });
    }

    function focus_floating() {
        _writeSocket.sendAction("FocusFloating", {});
    }
    function focus_tiling() {
        _writeSocket.sendAction("FocusTiling", {});
    }
    function switch_focus_between_floating_and_tiling() {
        _writeSocket.sendAction("SwitchFocusBetweenFloatingAndTiling", {});
    }

    // MoveFloatingWindow { id, x: PositionChange, y: PositionChange }
    // PositionChange: { "Relative": 10 } or { "Absolute": 100 }
    function move_floating_window(xDelta, yDelta, id = null) {
        _writeSocket.sendAction("MoveFloatingWindow", {
            id: id,
            x: {
                "Relative": xDelta
            },
            y: {
                "Relative": yDelta
            }
        });
    }

    function move_floating_window_absolute(x, y, id = null) {
        _writeSocket.sendAction("MoveFloatingWindow", {
            id: id,
            x: {
                "Absolute": x
            },
            y: {
                "Absolute": y
            }
        });
    }

    // =========================================================================
    // URGENCY
    // =========================================================================

    // Rust: id: u64 (Mandatory)
    function toggle_window_urgent(id) {
        if (id === undefined || id === null)
            console.warn("NiriIPC: toggle_window_urgent requires ID");
        _writeSocket.sendAction("ToggleWindowUrgent", {
            id: id
        });
    }
    function set_window_urgent(id) {
        if (id === undefined || id === null)
            console.warn("NiriIPC: set_window_urgent requires ID");
        _writeSocket.sendAction("SetWindowUrgent", {
            id: id
        });
    }
    function unset_window_urgent(id) {
        if (id === undefined || id === null)
            console.warn("NiriIPC: unset_window_urgent requires ID");
        _writeSocket.sendAction("UnsetWindowUrgent", {
            id: id
        });
    }

    // =========================================================================
    // COLUMN ACTIONS
    // =========================================================================

    function focus_column(index) {
        _writeSocket.sendAction("FocusColumn", {
            index: index
        });
    }
    function focus_column_left() {
        _writeSocket.sendAction("FocusColumnLeft", {});
    }
    function focus_column_right() {
        _writeSocket.sendAction("FocusColumnRight", {});
    }
    function focus_column_first() {
        _writeSocket.sendAction("FocusColumnFirst", {});
    }
    function focus_column_last() {
        _writeSocket.sendAction("FocusColumnLast", {});
    }
    function focus_column_right_or_first() {
        _writeSocket.sendAction("FocusColumnRightOrFirst", {});
    }
    function focus_column_left_or_last() {
        _writeSocket.sendAction("FocusColumnLeftOrLast", {});
    }

    function focus_column_or_monitor_left() {
        _writeSocket.sendAction("FocusColumnOrMonitorLeft", {});
    }
    function focus_column_or_monitor_right() {
        _writeSocket.sendAction("FocusColumnOrMonitorRight", {});
    }

    function move_column_left() {
        _writeSocket.sendAction("MoveColumnLeft", {});
    }
    function move_column_right() {
        _writeSocket.sendAction("MoveColumnRight", {});
    }
    function move_column_to_first() {
        _writeSocket.sendAction("MoveColumnToFirst", {});
    }
    function move_column_to_last() {
        _writeSocket.sendAction("MoveColumnToLast", {});
    }
    function move_column_to_index(index) {
        _writeSocket.sendAction("MoveColumnToIndex", {
            index: index
        });
    }

    function move_column_left_or_to_monitor_left() {
        _writeSocket.sendAction("MoveColumnLeftOrToMonitorLeft", {});
    }
    function move_column_right_or_to_monitor_right() {
        _writeSocket.sendAction("MoveColumnRightOrToMonitorRight", {});
    }

    function move_column_to_workspace(indexOrName, focus = true) {
        let ref = (typeof indexOrName === "number") ? {
            "Index": indexOrName
        } : {
            "Name": indexOrName.toString()
        };
        _writeSocket.sendAction("MoveColumnToWorkspace", {
            reference: ref,
            focus: focus
        });
    }
    function move_column_to_workspace_down(focus = true) {
        _writeSocket.sendAction("MoveColumnToWorkspaceDown", {
            focus: focus
        });
    }
    function move_column_to_workspace_up(focus = true) {
        _writeSocket.sendAction("MoveColumnToWorkspaceUp", {
            focus: focus
        });
    }

    // Rust: output: String
    function move_column_to_monitor(outputName) {
        _writeSocket.sendAction("MoveColumnToMonitor", {
            output: outputName
        });
    }
    function move_column_to_monitor_left() {
        _writeSocket.sendAction("MoveColumnToMonitorLeft", {});
    }
    function move_column_to_monitor_right() {
        _writeSocket.sendAction("MoveColumnToMonitorRight", {});
    }
    function move_column_to_monitor_up() {
        _writeSocket.sendAction("MoveColumnToMonitorUp", {});
    }
    function move_column_to_monitor_down() {
        _writeSocket.sendAction("MoveColumnToMonitorDown", {});
    }
    function move_column_to_monitor_previous() {
        _writeSocket.sendAction("MoveColumnToMonitorPrevious", {});
    }
    function move_column_to_monitor_next() {
        _writeSocket.sendAction("MoveColumnToMonitorNext", {});
    }

    function toggle_column_tabbed_display() {
        _writeSocket.sendAction("ToggleColumnTabbedDisplay", {});
    }
    // display: "Tabbed" | "Stack" | "SideBySide"
    function set_column_display(mode) {
        _writeSocket.sendAction("SetColumnDisplay", {
            display: mode
        });
    }

    function center_column() {
        _writeSocket.sendAction("CenterColumn", {});
    }
    function center_visible_columns() {
        _writeSocket.sendAction("CenterVisibleColumns", {});
    }
    function maximize_column() {
        _writeSocket.sendAction("MaximizeColumn", {});
    }
    function expand_column_to_available_width() {
        _writeSocket.sendAction("ExpandColumnToAvailableWidth", {});
    }

    // Rust: change: SizeChange
    function set_column_width_pixels(pixels) {
        _writeSocket.sendAction("SetColumnWidth", {
            change: {
                "SetFixed": pixels
            }
        });
    }
    function set_column_width_percent(percent) {
        _writeSocket.sendAction("SetColumnWidth", {
            change: {
                "SetProportion": percent
            }
        });
    }

    function switch_preset_column_width() {
        _writeSocket.sendAction("SwitchPresetColumnWidth", {});
    }
    function switch_preset_column_width_back() {
        _writeSocket.sendAction("SwitchPresetColumnWidthBack", {});
    }

    // =========================================================================
    // WORKSPACE ACTIONS
    // =========================================================================

    function focus_workspace(indexOrName) {
        let ref = (typeof indexOrName === "number") ? {
            "Index": indexOrName
        } : {
            "Name": indexOrName.toString()
        };
        _writeSocket.sendAction("FocusWorkspace", {
            reference: ref
        });
    }
    function focus_workspace_down() {
        _writeSocket.sendAction("FocusWorkspaceDown", {});
    }
    function focus_workspace_up() {
        _writeSocket.sendAction("FocusWorkspaceUp", {});
    }
    function focus_workspace_previous() {
        _writeSocket.sendAction("FocusWorkspacePrevious", {});
    }

    function move_workspace_down() {
        _writeSocket.sendAction("MoveWorkspaceDown", {});
    }
    function move_workspace_up() {
        _writeSocket.sendAction("MoveWorkspaceUp", {});
    }

    // Rust: index: usize, reference: Option<WorkspaceReferenceArg>
    function move_workspace_to_index(index, indexOrName = null) {
        let ref = null;
        if (indexOrName !== null) {
            if (typeof indexOrName === "string") {
                ref = {
                    "Name": indexOrName
                };
            } else if (typeof indexOrName === "number") {
                ref = {
                    "Index": indexOrName
                };
            }
        }
        _writeSocket.sendAction("MoveWorkspaceToIndex", {
            index: index,
            reference: ref
        });
    }

    // Rust: output: String, reference: Option<WorkspaceReferenceArg>
    function move_workspace_to_monitor(outputName, indexOrName = null) {
        let ref = null;
        if (indexOrName !== null) {
            if (typeof indexOrName === "string") {
                ref = {
                    "Name": indexOrName
                };
            } else if (typeof indexOrName === "number") {
                ref = {
                    "Index": indexOrName
                };
            }
        }
        _writeSocket.sendAction("MoveWorkspaceToMonitor", {
            output: outputName,
            reference: ref
        });
    }

    function move_workspace_to_monitor_left() {
        _writeSocket.sendAction("MoveWorkspaceToMonitorLeft", {});
    }
    function move_workspace_to_monitor_right() {
        _writeSocket.sendAction("MoveWorkspaceToMonitorRight", {});
    }
    function move_workspace_to_monitor_up() {
        _writeSocket.sendAction("MoveWorkspaceToMonitorUp", {});
    }
    function move_workspace_to_monitor_down() {
        _writeSocket.sendAction("MoveWorkspaceToMonitorDown", {});
    }
    function move_workspace_to_monitor_previous() {
        _writeSocket.sendAction("MoveWorkspaceToMonitorPrevious", {});
    }
    function move_workspace_to_monitor_next() {
        _writeSocket.sendAction("MoveWorkspaceToMonitorNext", {});
    }

    function set_workspace_name(name, workspaceIndex = null) {
        let ref = null;
        if (workspaceIndex !== null)
            ref = {
                "Index": workspaceIndex
            };
        _writeSocket.sendAction("SetWorkspaceName", {
            name: name,
            workspace: ref
        });
    }
    function unset_workspace_name(workspaceIndex = null) {
        let ref = null;
        if (workspaceIndex !== null)
            ref = {
                "Index": workspaceIndex
            };
        _writeSocket.sendAction("UnsetWorkspaceName", {
            reference: ref
        });
    }

    // =========================================================================
    // MONITOR ACTIONS
    // =========================================================================

    // Rust: FocusMonitor { output: String }
    function focus_monitor(outputName) {
        _writeSocket.sendAction("FocusMonitor", {
            output: outputName
        });
    }

    function focus_monitor_left() {
        _writeSocket.sendAction("FocusMonitorLeft", {});
    }
    function focus_monitor_right() {
        _writeSocket.sendAction("FocusMonitorRight", {});
    }
    function focus_monitor_up() {
        _writeSocket.sendAction("FocusMonitorUp", {});
    }
    function focus_monitor_down() {
        _writeSocket.sendAction("FocusMonitorDown", {});
    }
    function focus_monitor_previous() {
        _writeSocket.sendAction("FocusMonitorPrevious", {});
    }
    function focus_monitor_next() {
        _writeSocket.sendAction("FocusMonitorNext", {});
    }
}
