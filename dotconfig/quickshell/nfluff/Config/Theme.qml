pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Config

Singleton {
    id: root

    QtObject {
        id: _runtime_properties
        property string path: Config.initialized ? Config.themePath : ""
        property bool initialized: false
    }

    readonly property bool initialized: _runtime_properties.initialized
    readonly property string path: _runtime_properties.path

    readonly property alias colors: _colors
    readonly property alias typography: _typography
    readonly property alias shapes: _shapes
    readonly property alias spacing: _spacing

    QtObject {
        id: _colors
        readonly property alias on: _colors_on
        readonly property string primary: _theme.colors_primary
        readonly property string primaryContainer: _theme.colors_primaryContainer
        readonly property string secondary: _theme.colors_secondary
        readonly property string secondaryContainer: _theme.colors_secondaryContainer
        readonly property string tertiary: _theme.colors_tertiary
        readonly property string tertiaryContainer: _theme.colors_tertiaryContainer
        readonly property string error: _theme.colors_error
        readonly property string errorContainer: _theme.colors_errorContainer
        readonly property string background: _theme.colors_background
        readonly property string surface: _theme.colors_surface
        readonly property string surfaceVariant: _theme.colors_surfaceVariant
        readonly property string outline: _theme.colors_outline
        readonly property string shadow: _theme.colors_shadow
    }
    QtObject {
        id: _colors_on
        readonly property string primary: _theme.colors_onPrimary
        readonly property string primaryContainer: _theme.colors_onPrimaryContainer
        readonly property string secondary: _theme.colors_onSecondary
        readonly property string secondaryContainer: _theme.colors_onSecondaryContainer
        readonly property string tertiary: _theme.colors_onTertiary
        readonly property string tertiaryContainer: _theme.colors_onTertiaryContainer
        readonly property string error: _theme.colors_onError
        readonly property string errorContainer: _theme.colors_onErrorContainer
        readonly property string background: _theme.colors_onBackground
        readonly property string surface: _theme.colors_onSurface
        readonly property string surfaceVariant: _theme.colors_onSurfaceVariant
    }

    QtObject {
        id: _typography
        readonly property string fontFamily: _theme.typography_fontFamily
        readonly property alias large: _typography_large
        readonly property alias medium: _typography_medium
        readonly property alias small: _typography_small
    }
    QtObject {
        id: _typography_large
        readonly property int size: _theme.typography_largeSize
        readonly property int weight: _theme.typography_largeWeight
    }
    QtObject {
        id: _typography_medium
        readonly property int size: _theme.typography_mediumSize
        readonly property int weight: _theme.typography_mediumWeight
    }
    QtObject {
        id: _typography_small
        readonly property int size: _theme.typography_smallSize
        readonly property int weight: _theme.typography_smallWeight
    }

    QtObject {
        id: _shapes
        readonly property alias corner: _shapes_corner
    }
    QtObject {
        id: _shapes_corner
        readonly property int small: _theme.shapes_cornerSmall
        readonly property int medium: _theme.shapes_cornerMedium
        readonly property int large: _theme.shapes_cornerLarge
    }

    QtObject {
        id: _spacing
        readonly property int sm: _theme.spacing_sm
        readonly property int md: _theme.spacing_md
        readonly property int lg: _theme.spacing_lg
    }

    ThemeModel {
        id: _default_theme
        colors_primary: "#A78BFA"
        colors_onPrimary: "#1A102A"
        colors_primaryContainer: "#4B3A7A"
        colors_onPrimaryContainer: "#EDE4FF"
        colors_secondary: "#6C5EC9"
        colors_onSecondary: "#FFFFFF"
        colors_secondaryContainer: "#3D347F"
        colors_onSecondaryContainer: "#E8E3FF"
        colors_tertiary: "#7AD9FF"
        colors_onTertiary: "#00141A"
        colors_tertiaryContainer: "#1F3A54"
        colors_onTertiaryContainer: "#D3F5FF"
        colors_error: "#FFD98A"
        colors_onError: "#3A2600"
        colors_errorContainer: "#5A4100"
        colors_onErrorContainer: "#FFF2D4"
        colors_background: "#0C0A12"
        colors_onBackground: "#DCD4FF"
        colors_surface: "#130F20"
        colors_onSurface: "#E8E0FF"
        colors_surfaceVariant: "#2F2A44"
        colors_onSurfaceVariant: "#C4BEE0"
        colors_outline: "#3C335A"
        colors_shadow: "#000000"

        typography_fontFamily: "GeistMono NF"
        typography_largeSize: 32
        typography_largeWeight: 400
        typography_mediumSize: 16
        typography_mediumWeight: 500
        typography_smallSize: 11
        typography_smallWeight: 500

        shapes_cornerSmall: 4
        shapes_cornerMedium: 12
        shapes_cornerLarge: 28

        spacing_sm: 8
        spacing_md: 16
        spacing_lg: 24
    }

    ThemeModel {
        id: _theme
        defaults: _default_theme
    }

    FileView {
        id: _file
        path: _runtime_properties.path

        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
        blockAllReads: true
        blockWrites: true

        onLoadFailed: err => {
            Notifications.sendError("Theme Error", `Could not load theme at <i>${_runtime_properties.path}</i>. ${FileViewError.toString(err)}. Using default theme.`);
            console.error("Theme: failed to load theme file:", err);
        }

        onLoaded: () => {
            const t = text();
            root.parseConfig(t);
        }
    }

    function parseConfig(t) {
        let themeJSON = {};
        try {
            themeJSON = JSON.parse(t);
        } catch (err) {
            console.error("Theme: failed to parse theme file:", err);
            Notifications.sendError("Theme Error", `Could not parse theme at <i>${_runtime_properties.path}</i>. ${err.toString()}. Using default theme.`);
        }
        console.debug("Theme: parsed theme file");

        const errors = ThemeHelper.validateTheme(themeJSON);
        if (errors.length > 0) {
            Notifications.sendError("Config Error", `Could not parse theme at <i>${_runtime_properties.path}</i>.\n- ${errors.join("\n- ")}`);
            return;
        }

        console.debug("Theme: validated theme file");
        try {
            _theme.assign(themeJSON);
            console.debug("Theme: assigned theme file");
        } catch (err) {
            console.error("Theme: failed to parse theme file:", err);
            Notifications.sendError("Theme Error", `Could not parse theme at <i>${_runtime_properties.path}</i>. ${err.toString()}. Using default theme.`);
        }
    }
}
