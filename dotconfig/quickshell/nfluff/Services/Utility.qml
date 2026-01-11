pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
    id: root

    property var timesTable: [
"░ ░ ░ ░ ░ ░",
"░ ░ ░ ░ ░ ▓",
"░ ░ ░ ░ ░ █",
"░ ░ ░ ░ ▓ █",
"░ ░ ░ ░ █ █",
"░ ░ ░ ▓ █ █",
"░ ░ ░ █ █ █",
"░ ░ ▓ █ █ █",
"░ ░ █ █ █ █",
"░ ▓ █ █ █ █",
"░ █ █ █ █ █",
"▓ █ █ █ █ █",
    ]
    property var minutesTable: [
"░░░ ░░░",
"▓░░ ░░░",
"█░░ ░░░",
"█▓░ ░░░",
"██░ ░░░",
"██▓ ░░░",
"███ ░░░",
"███ ▓░░",
"███ █░░",
"███ █▓░",
"███ ██░",
"███ ██▓",
    ]
    function getTime(t) {
        var minutes = t.getMinutes();
        var hours = t.getHours();
        var t = "";
        t += timesTable[hours % 12];

        t += " ¤ ";
        t += minutesTable[Math.floor(minutes / 5)];

        return t;
    }
}
