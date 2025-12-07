// pragma Singleton
// pragma ComponentBehavior: Bound

// import QtCore
// import QtQuick
// import Quickshell
// import Quickshell.Io
// import qs.Services
// import qs.Config

// Singleton {
//     id: root

//     QtObject {
//         id: _runtime_properties
//         property string path: Config.initialized ? Config.layoutPath : ""
//         property bool initialized: false
//     }

//     readonly property bool initialized: _runtime_properties.initialized
//     readonly property string path: _runtime_properties.path

//     readonly property alias autohide: _layout.autohide
//     readonly property alias minWidth: _layout.minWidth
//     readonly property alias maxWidth: _layout.maxWidth
//     readonly property alias height: _layout.height
//     readonly property alias fullWidth: _layout.fullWidth
//     readonly property alias modules: _modules

//     QtObject {
//         id: _layout
//         property bool autohide: true
//         property int minWidth: 640
//         property int maxWidth: 1280
//         property int height: 50
//         property bool fullWidth: false
//     }

//     QtObject {
//         id: _modules
//         readonly property alias left: _modules_left
//         readonly property alias right: _modules_right
//         readonly property alias center: _modules_center
//     }
//     ListModel {
//         id: _modules_left
//         ListElement {
//             name: "workspaces"
//             config: {
//                 "format": "hh:mm"
//             }
//         }
//     }
//     ListModel {
//         id: _modules_right
//         ListElement {
//             name: "clock"
//             config: {
//                 "format": "hh:mm"
//             }
//         }
//     }
//     ListModel {
//         id: _modules_center
//         ListElement {
//             name: "workspaces"
//             config: {
//                 "format": "hh:mm"
//             }
//         }
//     }

//     ThemeModel {
//     }

//     ThemeModel {
//         id: _theme
//         defaults: _default_theme
//     }

//     FileView {
//         id: _file
//         path: _runtime_properties.path

//         watchChanges: true
//         onFileChanged: reload()
//         blockLoading: true
//         blockAllReads: true
//         blockWrites: true

//         onLoadFailed: err => {
//             Notifications.sendError("Theme Error", `Could not load theme at <i>${_runtime_properties.path}</i>. ${FileViewError.toString(err)}. Using default theme.`);
//             console.error("Theme: failed to load theme file:", err);
//         }

//         onLoaded: () => {
//             const t = text();
//             root.parseConfig(t);
//         }
//     }

//     function parseConfig(t) {
//         let themeJSON = {};
//         try {
//             themeJSON = JSON.parse(t);
//         } catch (err) {
//             console.error("Theme: failed to parse theme file:", err);
//             Notifications.sendError("Theme Error", `Could not parse theme at <i>${_runtime_properties.path}</i>. ${err.toString()}. Using default theme.`);
//         }
//         console.debug("Theme: parsed theme file");

//         const errors = ThemeHelper.validateTheme(themeJSON);
//         if (errors.length > 0) {
//             Notifications.sendError("Config Error", `Could not parse theme at <i>${_runtime_properties.path}</i>.\n- ${errors.join("\n- ")}`);
//             return;
//         }

//         console.debug("Theme: validated theme file");
//         try {
//             _theme.assign(themeJSON);
//             console.debug("Theme: assigned theme file");
//         } catch (err) {
//             console.error("Theme: failed to parse theme file:", err);
//             Notifications.sendError("Theme Error", `Could not parse theme at <i>${_runtime_properties.path}</i>. ${err.toString()}. Using default theme.`);
//         }
//     }
// }
