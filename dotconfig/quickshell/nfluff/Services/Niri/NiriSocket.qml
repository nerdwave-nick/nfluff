import QtQuick
import Quickshell.Io

Item {
    id: _root

    readonly property alias isConnected: _state.isConnected
    property alias connect: _state.shouldConnect

    property int reconnectionTimeoutBaseMs: 400
    property int reconnectionTimeoutCapMs: 15000

    property alias path: _socket.path

    signal messageReceived(var message)
    signal eventReceived(string eventName, var eventData)

    function sendAction(action, data = {}) {
        if (!_state.isConnected) {
            console.warn("NiriSocket", "sendAction", "not connected");
            return Promise.reject("not connected");
        }
        if (!action) {
            console.warn("NiriSocket", "sendAction", "action is null");
            return Promise.reject("action is null");
        }
        if (typeof action !== "string") {
            console.warn("NiriSocket", "sendAction", "action is not a string");
            return Promise.reject("action is not a string");
        }
        if (data && typeof data !== "object") {
            console.warn("NiriSocket", "sendAction", "data is not an object");
            return Promise.reject("data is not an object");
        }

        const payload = {
            Action: {
                [action]: data ?? {}
            }
        };
        return _socket.send(JSON.stringify(payload));
    }

    function sendString(data) {
        if (!_state.isConnected) {
            console.warn("NiriSocket", "sendString", "not connected");
            return Promise.reject("not connected");
        }
        if (!data) {
            console.warn("NiriSocket", "sendString", "data is null");
            return Promise.reject("data is null");
        }
        if (typeof data !== "string") {
            console.error("NiriSocket", "sendString", "data is not a string");
            return Promise.reject("data is not a string");
        }
        return _socket.send(data);
    }

    QtObject {
        id: _state
        property bool isConnected: false
        property bool shouldConnect: false
        property int reconnectAttempt: 0

        property var pendingRequests: []

        onShouldConnectChanged: {
            if (shouldConnect && !isConnected) {
                _connect();
            } else if (!shouldConnect) {
                _disconnect();
            }
        }

        function _purgePendingRequests(reason) {
            while (_state.pendingRequests.length > 0) {
                const req = _state.pendingRequests.shift();
                req.reject(reason);
            }
        }

        function _connect() {
            reconnectAttempt = 0;
            _reconnectionTimer.restartWithTimeout(0);
        }

        function _disconnect() {
            _purgePendingRequests("Socket disconnected");
            _socket.connected = false;
            reconnectAttempt = 0;
            _reconnectionTimer.stop();
        }

        function startReconnectAttempt() {
            _purgePendingRequests("Socket connection lost - reconnecting");
            const calc = _root.reconnectionTimeoutBaseMs * Math.pow(2, _state.reconnectAttempt);
            const maxDelay = Math.min(calc, _root.reconnectionTimeoutCapMs);
            const backoff = Math.floor(Math.random() * maxDelay) + 50;
            _reconnectionTimer.restartWithTimeout(backoff);
            reconnectAttempt++;
        }

        Component.onCompleted: {
            if (shouldConnect && !isConnected) {
                _connect();
            }
        }
    }

    Socket {
        id: _socket

        onConnectionStateChanged: {
            if (connected) {
                _state.isConnected = true;
                _state.reconnectAttempt = 0;
                return;
            }
            _state.isConnected = false;
            if (_state.shouldConnect) {
                _state.startReconnectAttempt();
            }
        }

        function send(data) {
            return new Promise((resolve, reject) => {
                _state.pendingRequests.push({
                    resolve,
                    reject
                });
                write(data);
                write("\n");
                flush();
            });
        }

        parser: SplitParser {
            onRead: data => {
                if (!data)
                    return;

                try {
                    const json = JSON.parse(data);
                    if (!json || typeof json !== "object") {
                        console.warn("NiriSocket: invalid read", json);
                        return;
                    }

                    _root.messageReceived(json);
                    const keys = Object.keys(json);
                    for (const key of keys) {
                        if (key === "Ok" || key === "Err") {
                            if (_state.pendingRequests.length !== 0) {
                                const req = _state.pendingRequests.shift();
                                if (key === "Ok") {
                                    req.resolve(json[key]);
                                } else {
                                    req.reject(json[key]);
                                }
                            }
                            continue;
                        }
                        const eventData = json[key];
                        _root.eventReceived(key, eventData);
                    }
                } catch (e) {
                    console.warn("NiriSocket: Parse error", e);
                }
            }
        }
    }

    Timer {
        id: _reconnectionTimer
        interval: 0
        triggeredOnStart: false
        repeat: false
        onTriggered: {
            if (!_state.shouldConnect)
                return;
            _socket.connected = true;
        }

        function restartWithTimeout(timeout) {
            interval = timeout;
            restart();
        }
    }
}
