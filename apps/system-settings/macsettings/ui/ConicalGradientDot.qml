import QtQuick
import QtQuick.Shapes

// Радужная точка «Разноцветный» (акцент из темы)
Shape {
    id: root
    layer.enabled: true
    layer.samples: 4
    ShapePath {
        strokeWidth: 0
        fillGradient: ConicalGradient {
            centerX: root.width / 2; centerY: root.height / 2
            GradientStop { position: 0.0; color: "#ff3b30" }
            GradientStop { position: 0.2; color: "#ffcc00" }
            GradientStop { position: 0.4; color: "#34c759" }
            GradientStop { position: 0.6; color: "#007aff" }
            GradientStop { position: 0.8; color: "#af52de" }
            GradientStop { position: 1.0; color: "#ff3b30" }
        }
        PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.width / 2; radiusY: root.height / 2; startAngle: 0; sweepAngle: 360 }
    }
}
