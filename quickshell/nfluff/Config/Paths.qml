pragma Singleton
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Config

Singleton {
    id: root

    function normalize(path) {
        if (path === undefined || path === "") {
            return "";
        }
        return path.replace("file://", "").replace("~", Quickshell.env("HOME"));
    }
}
