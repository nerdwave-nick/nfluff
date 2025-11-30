import QtQuick

Item {
    id: _root

    required property MouseArea mouseArea

    // Configuration: Controls whether the bar reacts to transient inputs (hover/timer).
    required property bool autoHideEnabled

    required property bool forceClosed

    // --- Public State ---

    // Logic: If autohide is disabled, the bar is always pinned open. Otherwise, follow locks/hover/timer.
    readonly property bool shouldShow: !forceClosed && (!autoHideEnabled || _state.isHovered || _state.showTimerRunning || _state.openLocks.length > 0)

    // true if shouldshow is true, or if an animation/external system requires the data to be alive.
    readonly property bool isShowing: _root.shouldShow || _state.hidingLocks.length > 0

    // 3. URGENCY
    readonly property bool hasUrgency: _state.urgentSources.length > 0

    // --- Internal State ---

    QtObject {
        id: _state

        readonly property bool isHovered: _root.mouseArea ? _root.mouseArea.containsMouse : false

        property alias showTimerRunning: _showTimer.running
        property double hideDeadline: 0

        property var openLocks: []
        property var hidingLocks: []
        property var urgentSources: []
    }

    // show for x ms
    function requestShow(durationMs = 1500) {
        // if autohide is disabled or the bar is already forced closed,
        // ignore transient requests
        if (_root.forceClosed || !_root.autoHideEnabled)
            return;

        let now = Date.now();
        let requestedDeadline = now + durationMs;

        if (!_state.showTimerRunning) {
            _state.hideDeadline = requestedDeadline;
            _showTimer.interval = durationMs;
            _showTimer.start();
            return;
        }

        // extend only
        if (requestedDeadline > _state.hideDeadline) {
            _state.hideDeadline = requestedDeadline;
            _showTimer.interval = requestedDeadline - now;
            _showTimer.restart();
        }
    }

    // i am a menu. keep shouldShow"
    function lockOpen(key, active) {
        _updateList(_state.openLocks, key, active, "openLocks");
    }

    // i am an animation. keep isShowing = true
    function preventHiding(key, active) {
        _updateList(_state.hidingLocks, key, active, "hidingLocks");
    }

    // i am critical. note my presence and optionally request showing
    function setUrgent(key, active, durationMs = 3000) {
        _updateList(_state.urgentSources, key, active, "urgentSources");
        if (active && durationMs > 0)
            requestShow(durationMs);
    }

    // Helper to maintain immutability
    function _updateList(currentList, key, active, propName) {
        if (active) {
            if (currentList.indexOf(key) === -1) {
                var list = currentList.slice();
                list.push(key);
                _state[propName] = list;
            }
        } else {
            if (currentList.indexOf(key) !== -1) {
                var list = currentList.filter(k => k !== key);
                _state[propName] = list;
            }
        }
    }

    Timer {
        id: _showTimer
        repeat: false
    }
}
