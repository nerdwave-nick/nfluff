pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Services
import qs.Common
import qs.Config

Singleton {
    id: root

    readonly property bool initialized: runtime_properties.initialized

    QtObject {
        id: runtime_properties
        property bool initialized: false
        readonly property string location: `${StandardPaths.writableLocation(StandardPaths.ConfigLocation)}/nfluff`
        readonly property string filename: "status-bar.json"
        readonly property string path: `${location}/${filename}`
        readonly property string trimmedLocation: location.replace("file://", "")
        readonly property string trimmedPath: `${trimmedLocation}/${filename}`
    }

    readonly property alias  themePath: _config.themePath
    readonly property alias layoutPath: _config.layoutPath
    readonly property alias autohide: _config.autohide

    QtObject {
        id: _default_config
        property string themePath: ""
        property string layoutPath: ""
        property bool autohide: true
    }
    QtObject {
        id: _config
        property string themePath: _default_config.themePath
        property string layoutPath: _default_config.layoutPath
        property bool autohide: _default_config.autohide

        function assignConfig(config) {
            _config.themePath = Paths.normalize(config.themePath) ?? _default_config.layoutPath;
            _config.layoutPath = config.layoutPath ?? _default_config.themePath;
            _config.autohide = config.autohide ?? _default_config.autohide;
            console.log("Config: assignConfig", _config.themePath, _config.layoutPath, _config.autohide);
        }
    }

    FileView {
        id: configFile
        path: runtime_properties.path

        function getConfigErrors(config) {
            if (typeof config.themePath !== "string") {
                console.error("Config: themePath must be a string", typeof config.themePath);
                return ["themePath must be a string"];
            }

            return [];
        }

        // when changes are made on disk, reload the file's content
        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
        blockAllReads: true
        blockWrites: true

        onLoadFailed: err => {
            Notifications.sendError("Config Error", `Could not load config at <i>${runtime_properties.trimmedPath}</i>. ${FileViewError.toString(err)}. Using default configuration.`);
            console.error("Config: failed to load config file:", err);
        }

        onLoaded: () => {
            const t = text();
            console.debug("Config: loaded config file", t);
            root.parseConfig(t);
            runtime_properties.initialized = true;
        }
    }

    function parseConfig(t) {
        let configJSON = {};
        try {
            configJSON = JSON.parse(t);
        } catch (err) {
            console.error("Config: failed to parse config file:", err);
            Notifications.sendError("Config Error", `Could not parse config at <i>${runtime_properties.trimmedPath}</i>. ${err.toString()}. Using default configuration.`);
        }

        const errors = configFile.getConfigErrors(configJSON);
        if (errors.length > 0) {
            Notifications.sendError("Config Error", `Could not parse config at <i>${runtime_properties.trimmedPath}</i>.\n- ${errors.join("\n- ")}`);
            return;
        }

        try {
            _config.assignConfig(configJSON);
        } catch (err) {
            console.error("Config: failed to parse config file:", err);
            Notifications.sendError("Config Error", `Could not parse config at <i>${runtime_properties.trimmedPath}</i>. ${err.toString()}. Using default configuration.`);
        }
    }
}
