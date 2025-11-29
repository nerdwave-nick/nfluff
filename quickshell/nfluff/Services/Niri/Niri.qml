pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: _root

    property alias connect: _ipc.connect
    property alias socketPath: _ipc.socketPath
    readonly property alias writeConnected: _ipc.writeConnected
    readonly property alias readConnected: _ipc.readConnected

    readonly property alias ipc: _ipc
    readonly property alias bus: _bus
    readonly property alias state: _state

    NiriIPC {
        id: _ipc
        connect: _root.connect
    }

    NiriEventBus {
        id: _bus
        ipc: _ipc
    }

    NiriState {
        id: _state
        bus: _bus
    }
}
