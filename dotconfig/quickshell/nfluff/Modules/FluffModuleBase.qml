pragma ComponentBehavior: Bound

import QtQuick
import qs.Modules.FluffBar

Item {
    id: _root
    required property string output
    required property FluffBarController fluffBarController
    required property double animationScale
}
