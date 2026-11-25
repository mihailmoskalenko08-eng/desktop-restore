import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: win
    required property QtObject backend
    width: 1120
    height: 720
    minimumWidth: 870
    minimumHeight: 570
    visible: true
    title: "Верни рабочий стол"

    readonly property bool dark: backend.dark
    readonly property color paper: dark ? "#1b1b18" : "#f4f0e6"
    readonly property color panel: dark ? "#24241f" : "#faf7ef"
    readonly property color ink: dark ? "#f4efe4" : "#25251e"
    readonly property color muted: dark ? "#b5b2a3" : "#655f52"
    readonly property color rule: dark ? "#3f4037" : "#ddd6c9"
    readonly property color accent: ["#acd884", "#86ccc0", "#f1b584", "#b8aeef"][backend.tone]
    readonly property color tint: Qt.tint(paper, Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.14 : 0.28))
    readonly property string serif: Qt.platform.os === "windows" ? "Georgia" : "DejaVu Serif"
    readonly property int motion: 175
    color: paper

    component Body: Text {
        color: win.ink
        font.pixelSize: 15
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }

    component Action: Button {
        id: action
        property bool primary: false
        font.pixelSize: 14
        font.weight: Font.DemiBold
        leftPadding: 16
        rightPadding: 16
        topPadding: 9
        bottomPadding: 9
        opacity: enabled ? 1 : 0.45
        contentItem: Body {
            text: action.text
            color: action.primary ? "#24261c" : win.ink
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font: action.font
        }
        background: Rectangle {
            radius: 16
            border.width: action.visualFocus || !action.primary ? 1 : 0
            border.color: action.visualFocus ? win.ink : win.rule
            color: action.primary
                   ? (action.down ? Qt.darker(win.accent, 1.12) : win.accent)
                   : (action.down || action.hovered ? win.tint : win.panel)
            Behavior on color { ColorAnimation { duration: win.motion } }
        }
    }

    component Field: TextField {
        id: field
        color: win.ink
        placeholderTextColor: win.muted
        selectByMouse: true
        font.pixelSize: 15
        padding: 12
        background: Rectangle {
            color: win.paper
            radius: 12
            border.color: field.activeFocus ? win.accent : win.rule
        }
    }

    component Sheet: Popup {
        padding: 24
        modal: true
        focus: true
        background: Rectangle {
            color: win.panel
            border.color: win.rule
            radius: 20
        }
        Overlay.modal: Rectangle { color: "#55000000" }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: win.motion }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: win.motion }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: win.tint
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            GradientStop { position: 0.68; color: win.paper }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 262
            color: win.panel
            Rectangle { width: 1; height: parent.height; anchors.right: parent.right; color: win.rule }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Rectangle {
                        width: 11; height: 11; radius: 6
                        color: win.accent
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    Body { text: "Верни рабочий стол"; font.weight: Font.DemiBold }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }
                Body { text: "Рабочие наборы"; color: win.muted; font.pixelSize: 13 }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: backend.groups
                    ScrollBar.vertical: ScrollBar { }
                    delegate: ItemDelegate {
                        id: entry
                        required property var modelData
                        width: ListView.view.width
                        height: 40
                        leftPadding: 12 + Math.min(modelData.depth, 5) * 13
                        rightPadding: 10
                        onClicked: backend.select(modelData.key)
                        contentItem: Body {
                            text: (entry.modelData.depth ? "↳  " : "") + entry.modelData.name
                            font.weight: entry.modelData.active ? Font.DemiBold : Font.Normal
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 12
                            color: entry.modelData.active || entry.hovered ? win.tint : "transparent"
                            border.color: win.accent
                            border.width: entry.visualFocus ? 1 : 0
                            Behavior on color { ColorAnimation { duration: win.motion } }
                        }
                    }
                }
                Action {
                    Layout.fillWidth: true
                    text: "+ Набор"
                    onClicked: nameSheet.begin("new")
                }
                Action {
                    Layout.fillWidth: true
                    text: win.dark ? "Светлая тема" : "Тёмная тема"
                    onClicked: backend.toggleTheme()
                }
            }
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 36
                spacing: 15
                RowLayout {
                    Layout.fillWidth: true
                    Body { Layout.fillWidth: true; text: backend.trail || "Рабочий стол"; color: win.muted }
                    Action {
                        text: "+ Тема"; enabled: backend.selected !== ""
                        onClicked: nameSheet.begin("topic")
                    }
                    Action {
                        text: "⋯"; enabled: backend.selected !== ""
                        Accessible.name: "Действия с набором или темой"
                        onClicked: groupMenu.popup()
                        Menu {
                            id: groupMenu
                            MenuItem { text: "Переименовать"; onTriggered: nameSheet.begin("rename") }
                            MenuItem { text: "Удалить"; onTriggered: confirmGroup.open() }
                        }
                    }
                }
                Body {
                    Layout.fillWidth: true
                    text: backend.title
                    font.family: win.serif
                    font.pixelSize: 54
                }
                RowLayout {
                    Layout.fillWidth: true
                    Body {
                        Layout.fillWidth: true
                        text: backend.resources.length ? "Ресурсов в теме: " + backend.resources.length : "Ресурсы"
                        color: win.muted
                    }
                    Action { text: "+ Добавить"; enabled: backend.selected !== ""; onClicked: addSheet.begin() }
                    Action {
                        text: "Открыть всё"
                        primary: true
                        enabled: backend.resources.length > 0
                        onClicked: backend.openResources(-1)
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: cards
                        anchors.fill: parent
                        clip: true
                        cellWidth: width / (width >= 700 ? 3 : 2)
                        cellHeight: 112
                        model: backend.resources
                        ScrollBar.vertical: ScrollBar { }
                        delegate: Rectangle {
                            id: card
                            required property int index
                            required property var modelData
                            width: cards.cellWidth - 10
                            height: cards.cellHeight - 10
                            radius: 17
                            color: cardOpen.hovered ? win.tint : win.panel
                            border.color: win.rule
                            Behavior on color { ColorAnimation { duration: win.motion } }

                            Button {
                                id: cardOpen
                                anchors.fill: parent
                                Accessible.name: "Открыть " + card.modelData.name
                                background: null
                                onClicked: backend.openResources(card.index)
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 13
                                spacing: 11
                                Rectangle {
                                    width: 38; height: 38; radius: 12; color: win.accent
                                    Body {
                                        anchors.centerIn: parent
                                        text: card.modelData.name.substring(0, 1).toUpperCase()
                                        color: "#23251b"
                                        font.weight: Font.DemiBold
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Body { Layout.fillWidth: true; text: card.modelData.name; font.weight: Font.DemiBold }
                                    Body { Layout.fillWidth: true; text: card.modelData.kind; color: win.muted; font.pixelSize: 13 }
                                }
                                Action {
                                    text: "⋯"; leftPadding: 8; rightPadding: 8
                                    Accessible.name: "Действия с ресурсом"
                                    onClicked: resourceMenu.popup()
                                    Menu {
                                        id: resourceMenu
                                        MenuItem {
                                            text: "Изменить"
                                            visible: card.modelData.kind !== "Приложение"
                                            height: visible ? implicitHeight : 0
                                            onTriggered: addSheet.beginEdit(card.index, card.modelData)
                                        }
                                        MenuItem { text: "Убрать из темы"; onTriggered: backend.removeResource(card.index) }
                                    }
                                }
                            }
                        }
                    }

                    SequentialAnimation {
                        id: switchCards
                        PropertyAction { target: cards; property: "opacity"; value: 0.35 }
                        NumberAnimation { target: cards; property: "opacity"; to: 1; duration: win.motion; easing.type: Easing.OutCubic }
                    }
                    Connections {
                        target: backend
                        function onChanged() {
                            if (stage.lastTopic !== backend.selected) {
                                stage.lastTopic = backend.selected
                                switchCards.restart()
                            }
                        }
                    }
                    Column {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, 360)
                        spacing: 12
                        visible: backend.resources.length === 0
                        Body {
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            text: backend.selected ? "С чего начнём?" : "Создай первый набор"
                            font.family: win.serif; font.pixelSize: 29
                        }
                        Body {
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            text: backend.selected ? "Добавь программы или перетащи сюда файлы." : "Собери всё нужное для одного занятия."
                            elide: Text.ElideNone
                            wrapMode: Text.Wrap
                            color: win.muted
                        }
                    }
                    DropArea {
                        anchors.fill: parent
                        enabled: backend.selected !== ""
                        onDropped: drop => {
                            if (drop.hasUrls)
                                backend.dropFiles(drop.urls)
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: parent.containsDrag
                            color: "#4080aa60"
                            border.color: win.accent
                            border.width: 2
                            radius: 18
                        }
                    }
                }
            }
            property string lastTopic: backend.selected
        }
    }

    Sheet {
        id: nameSheet
        objectName: "nameSheet"
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 390
        property string mode: "new"
        function begin(next) {
            mode = next
            groupName.text = next === "rename" ? backend.title : ""
            open()
        }
        onOpened: groupName.forceActiveFocus()
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            Body {
                text: nameSheet.mode === "rename" ? "Переименовать" : nameSheet.mode === "topic" ? "Новая тема" : "Новый набор"
                font.family: win.serif; font.pixelSize: 28
            }
            Field {
                id: groupName
                objectName: "groupName"
                Layout.fillWidth: true
                placeholderText: "Название"
                onAccepted: saveName.clicked()
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Action { text: "Отмена"; onClicked: nameSheet.close() }
                Action {
                    id: saveName
                    text: "Сохранить"; primary: true; enabled: groupName.text.trim() !== ""
                    onClicked: { if (backend.groupAction(nameSheet.mode, groupName.text)) nameSheet.close() }
                }
            }
        }
    }

    Sheet {
        id: confirmGroup
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 400
        ColumnLayout {
            anchors.fill: parent
            spacing: 14
            Body { text: "Удалить набор или тему?"; font.family: win.serif; font.pixelSize: 24 }
            Body { Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; text: "Вложенные темы и списки ресурсов исчезнут из приложения." }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Action { text: "Отмена"; onClicked: confirmGroup.close() }
                Action { text: "Удалить"; primary: true; onClicked: { confirmGroup.close(); backend.removeGroup() } }
            }
        }
    }

    Drawer {
        id: addSheet
        objectName: "addSheet"
        edge: Qt.RightEdge
        width: 435
        height: win.height
        padding: 24
        dragMargin: 0
        modal: true
        background: Rectangle { color: win.panel; border.color: win.rule }
        Overlay.modal: Rectangle { color: "#55000000" }
        enter: Transition { SmoothedAnimation { velocity: 2000 } }
        exit: Transition { SmoothedAnimation { velocity: 2500 } }
        property bool manual: false
        property int editing: -1
        property var picked: []
        readonly property var manualTypes: ["Сайт", "Программа", "Файл", "Папка"]
        readonly property var matches: backend.apps.filter(entry => entry.name.toLocaleLowerCase().includes(search.text.trim().toLocaleLowerCase()))
        function begin() {
            manual = false
            editing = -1
            picked = []
            search.text = ""
            clearManual()
            backend.loadApps()
            open()
        }
        function clearManual() {
            manualKind.currentIndex = 0
            manualName.text = ""
            manualTarget.text = ""
            manualArguments.text = ""
        }
        function beginEdit(index, item) {
            editing = index
            manual = true
            manualKind.currentIndex = manualTypes.indexOf(item.kind)
            manualName.text = item.name
            manualTarget.text = item.target
            manualArguments.text = item.arguments || ""
            open()
        }
        function toggle(key) {
            picked = picked.includes(key) ? picked.filter(item => item !== key) : picked.concat([key])
        }
        onOpened: (manual ? manualTarget : search).forceActiveFocus()

        ColumnLayout {
            anchors.fill: parent
            spacing: 13
            RowLayout {
                Layout.fillWidth: true
                Body {
                    Layout.fillWidth: true
                    text: addSheet.editing >= 0 ? "Изменить ресурс" : addSheet.manual ? "Добавить вручную" : "Добавить"
                    font.family: win.serif; font.pixelSize: 32
                }
                Action { text: "×"; Accessible.name: "Закрыть"; onClicked: addSheet.close() }
            }
            Body { Layout.fillWidth: true; text: backend.title; color: win.muted }

            Field { id: search; objectName: "appSearch"; Layout.fillWidth: true; visible: !addSheet.manual; placeholderText: "Поиск программ из меню «Пуск»" }
            Body {
                Layout.fillWidth: true
                visible: !addSheet.manual && !addSheet.matches.length
                text: backend.appStatus || "По этому запросу ничего не найдено."
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                color: win.muted
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !addSheet.manual
                clip: true
                model: addSheet.matches
                ScrollBar.vertical: ScrollBar { }
                delegate: CheckDelegate {
                    id: appEntry
                    required property var modelData
                    width: ListView.view.width
                    text: modelData.name
                    checked: addSheet.picked.includes(modelData.target)
                    onClicked: addSheet.toggle(modelData.target)
                    contentItem: Body { text: appEntry.text; rightPadding: 26; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 10; color: appEntry.hovered || appEntry.checked ? win.tint : "transparent" }
                }
            }
            Action {
                Layout.fillWidth: true
                visible: !addSheet.manual
                primary: true
                enabled: addSheet.picked.length > 0
                text: "Добавить выбранные" + (addSheet.picked.length ? " · " + addSheet.picked.length : "")
                onClicked: { if (backend.addApps(addSheet.picked)) addSheet.close() }
            }
            Action {
                Layout.fillWidth: true
                visible: !addSheet.manual
                text: "Добавить вручную"
                onClicked: { addSheet.manual = true; manualTarget.forceActiveFocus() }
            }

            ComboBox { id: manualKind; Layout.fillWidth: true; visible: addSheet.manual; model: addSheet.manualTypes }
            Body {
                visible: addSheet.manual
                text: manualKind.currentText === "Сайт" ? "Адрес сайта" : "Путь"
            }
            RowLayout {
                Layout.fillWidth: true
                visible: addSheet.manual
                Field {
                    id: manualTarget
                    objectName: "manualTarget"
                    Layout.fillWidth: true
                    placeholderText: manualKind.currentText === "Сайт" ? "https://…" : "Вставь путь"
                }
                Action {
                    visible: manualKind.currentText !== "Сайт"
                    text: "Обзор…"
                    onClicked: {
                        const path = backend.browse(manualKind.currentText)
                        if (path) manualTarget.text = path
                    }
                }
            }
            Field { id: manualName; Layout.fillWidth: true; visible: addSheet.manual; placeholderText: "Название (необязательно)" }
            Field {
                id: manualArguments
                Layout.fillWidth: true
                visible: addSheet.manual && manualKind.currentText === "Программа"
                placeholderText: "Аргументы запуска (необязательно)"
            }
            Item { Layout.fillHeight: true; visible: addSheet.manual }
            Action {
                Layout.fillWidth: true
                visible: addSheet.manual
                primary: true
                text: addSheet.editing >= 0 ? "Сохранить" : "Добавить"
                enabled: manualTarget.text.trim() !== ""
                onClicked: {
                    if (backend.saveResource(addSheet.editing, manualKind.currentText, manualName.text,
                                             manualTarget.text, manualArguments.text))
                        addSheet.close()
                }
            }
            Action {
                Layout.fillWidth: true
                visible: addSheet.manual && addSheet.editing < 0
                text: "К списку программ"
                onClicked: { addSheet.manual = false; search.forceActiveFocus() }
            }
        }
    }

    Popup {
        id: toast
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2); y: parent.height - height - 25
        padding: 13
        closePolicy: Popup.NoAutoClose
        z: 20
        background: Rectangle { color: win.dark ? "#eae5d9" : "#24241f"; radius: 14 }
        contentItem: Body { id: toastText; color: win.dark ? "#25251e" : "#faf7ef"; elide: Text.ElideNone }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: win.motion } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: win.motion } }
        Timer { id: toastTimer; interval: 3500; onTriggered: toast.close() }
        Connections {
            target: backend
            function onToast(message) { toastText.text = message; toast.open(); toastTimer.restart() }
        }
    }
}
