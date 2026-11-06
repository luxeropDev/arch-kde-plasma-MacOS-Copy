import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

// Жирное название активного приложения рядом с меню Apple
PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: true
        filterByActivity: true
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    readonly property string appName: {
        const idx = tasks.activeTask
        if (!idx || !idx.valid) return "Finder"
        const name = tasks.data(idx, TaskManager.AbstractTasksModel.AppName)
        return name && name.length ? name : "Finder"
    }

    fullRepresentation: PC3.Label {
        Layout.minimumWidth: implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.maximumWidth: Kirigami.Units.gridUnit * 14
        Layout.fillHeight: true
        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.smallSpacing
        verticalAlignment: Text.AlignVCenter
        text: root.appName
        font.weight: Font.Bold
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }
}
