pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    function normalize(path) {
        if (path === undefined || path === "") {
            return "";
        }
        return path.replace("file://", "").replace("~", Quickshell.env("HOME"));
    }
}
