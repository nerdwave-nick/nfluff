pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
    id: root

    function sendError(title, body, action) {
            Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "nfluff", "-i", "dialog-error-symbolic", title, body]);
    }
    function sendWarning(title, body) {
            Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "nfluff", "-i", "dialog-warning", title, body]);
    }
    function sendInfo(title, body) {
        Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "nfluff", "-i", "dialog-info", title, body]);
    }
}
