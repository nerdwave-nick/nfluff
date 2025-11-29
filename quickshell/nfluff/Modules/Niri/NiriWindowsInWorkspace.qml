pragma ComponentBehavior: Bound

import QtQuick
// import Quickshell
import qs.Modules
import qs.Services.Niri
import qs.Components
import qs.Config

GenericPerMonitorModule {
    id: _root
    // --- Layout ---
    // Auto-size to fit content so it can be centered/anchored in a bar
    width: _view.contentWidth
    height: 30

    QtObject {
        id: _state
        property int activeWsId: Niri.state.getActiveWorkspaceId(_root.output)
        property var sourceWindows: Niri.state.getWindowsForWorkspace(_state.activeWsId)
        onSourceWindowsChanged: _root._sync()
    }

    // --- 2. The Sync Engine ---

    ListModel {
        id: _model
        // Roles: id, title, app_id, is_focused, etc.
    }

    function _sync() {
        const source = _state.sourceWindows;
        const count = source.length;

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

    // --- 3. Rendering ---

    ListView {
        id: _view
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 4

        // Prevent scrolling interaction for a static bar
        interactive: false

        model: _model

        // --- Animations ---

        // Reordering (e.g. dragging a window left/right)
        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 100
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
                duration: 150
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 150
            }
        }

        // Close
        remove: Transition {
            NumberAnimation {
                property: "scale"
                to: 0.8
                duration: 150
            }
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 150
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

            anchors.verticalCenter: parent.verticalCenter
            cornerRadius: Theme.shapes.corner.small
            implicitHeight: 10
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
            onLeftClicked: Niri.ipc.focus_window(id)
            onRightClicked: {
                Niri.ipc.focus_window(id);
                Niri.ipc.center_window();
            }
            onMiddleClicked: {
                Niri.ipc.focus_window(id);
                Niri.ipc.close_window();
            }
        }

        // delegate: Rectangle {
        //     id: _delegate
        //     width: 200
        //     height: parent.height
        //     radius: 4

        //     required property int id
        //     required property var layout
        //     required property var title
        //     required property var app_id

        //     // --- Styling State ---
        //     // NiriState handles the focused ID globally.
        //     // We compare our local ID to the Singleton.
        //     readonly property bool isFocused: id === Niri.state.focusedWindowId

        //     // Helper for floating windows vs tiling
        //     readonly property bool isFloating: !layout || !layout.pos_in_scrolling_layout

        //     color: isFocused ? "#bd93f9" : "#44475a" // Dracula theme
        //     border.width: isFocused ? 2 : 0
        //     border.color: "#ffffff"

        //     // Animate Focus Color
        //     Behavior on color {
        //         ColorAnimation {
        //             duration: 100
        //         }
        //     }

        //     // --- Interaction ---
        //     TapHandler {
        //         onTapped: Niri.ipc.focus_window(parent.id)
        //     }

        //     // --- Content ---
        //     Row {
        //         anchors.centerIn: parent
        //         spacing: 6
        //         width: parent.width - 16

        //         // Icon (Optional, requires Quickshell image services)
        //         // Image {
        //         //     source: Quickshell.iconPath(app_id)
        //         //     width: 16; height: 16
        //         // }

        //         Text {
        //             text: _delegate.title || _delegate.app_id || "Window"
        //             color: _delegate.isFocused ? "#282a36" : "#f8f8f2"
        //             font.bold: _delegate.isFocused
        //             elide: Text.ElideRight
        //             width: parent.width // Adjust if using Icon
        //             verticalAlignment: Text.AlignVCenter
        //         }
        //     }

        //     // Indicator for Floating Windows
        //     Rectangle {
        //         visible: _delegate.isFloating
        //         width: 4
        //         height: 4
        //         radius: 2
        //         color: "cyan"
        //         anchors.top: parent.top
        //         anchors.right: parent.right
        //         anchors.margins: 3
        //     }
        // }
    }
}
// pragma ComponentBehavior: Bound

// import QtQuick
// import QtQuick.Layouts
// import qs.Services.Niri
// import qs.Components
// import qs.Config
// import qs.Modules

// GenericPerMonitorModule {
//     id: _root
//     RowLayout {
//         id: _row
//         anchors.centerIn: parent
//         spacing: Theme.spacing.sm
//         Repeater {
//             model: Niri.state.getWindowsForWorkspace(Niri.state.getActiveWorkspaceId(_root.output))

//             PillButton {
//                 required property int id
//                 required property int workspace_id
//                 required property bool is_focused

//                 cornerRadius: Theme.shapes.corner.small
//                 implicitHeight: 10
//                 backgroundColor: is_focused ? Theme.colors.primary : Theme.colors.surfaceVariant
//                 hoverBackgroundColor: Qt.darker(Theme.colors.primary, 1.3)
//                 pressedBackgroundColor: Theme.colors.tertiary
//                 onLeftClicked: Niri.ipc.focus_window(id)
//                 onRightClicked: {
//                     Niri.ipc.focus_window(id);
//                     Niri.ipc.center_window();
//                 }
//                 onMiddleClicked: {
//                     Niri.ipc.focus_window(id);
//                     Niri.ipc.close_window();
//                 }
//             }
//         }
//     }
// }
