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
    readonly property color paper: dark ? "#151418" : "#f5f1eb"
    readonly property color panel: dark ? "#201f25" : "#fcf9f4"
    readonly property color ink: dark ? "#f5eff7" : "#282230"
    readonly property color muted: dark ? "#bdb1c4" : "#675d70"
    readonly property color rule: dark ? "#3c3643" : "#e4dbe2"
    readonly property var accentNames: ["Сирень", "Пудра", "Абрикос", "Мята"]
    readonly property var accents: ["#d8c5fb", "#f1bbd2", "#f3c397", "#a7dbcf"]
    readonly property color accent: accents[backend.accent]
    readonly property color accentInk: "#302342"
    readonly property color tint: Qt.tint(panel, Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.13 : 0.5))
    readonly property string serif: Qt.platform.os === "windows" ? "Georgia" : "DejaVu Serif"
    readonly property int motion: backend.motion ? 220 : 0
    readonly property int revealTime: backend.motion ? 480 : 0
    color: paper
    palette.window: panel
    palette.base: panel
    palette.text: ink
    palette.windowText: ink
    palette.button: panel
    palette.buttonText: ink
    palette.highlight: accent
    palette.highlightedText: accentInk
    Behavior on color { ColorAnimation { duration: win.motion } }

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
        scale: down && win.motion ? 0.972 : 1
        Behavior on scale { NumberAnimation { duration: win.motion / 2; easing.type: Easing.OutCubic } }
        contentItem: Body {
            text: action.text
            color: action.primary ? win.accentInk : win.ink
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

    component Reveal: Item {
        id: reveal
        property bool selected: false
        property bool hovered: false
        property bool focused: false
        Rectangle {
            anchors.fill: parent
            radius: 15
            color: reveal.hovered ? win.tint : win.panel
            border.color: reveal.focused ? win.accent : win.rule
            Behavior on color { ColorAnimation { duration: win.motion } }
        }
        Rectangle {
            height: parent.height
            width: reveal.selected ? parent.width : 0
            opacity: reveal.selected ? 1 : 0
            radius: 15
            color: win.accent
            Behavior on width { NumberAnimation { duration: win.revealTime; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: win.motion } }
        }
    }

    component SoftMenu: Menu {
        width: 210
        padding: 6
        spacing: 3
        background: Rectangle { color: win.panel; border.color: win.rule; radius: 16 }
    }

    component SoftMenuItem: MenuItem {
        id: choice
        implicitHeight: 42
        leftPadding: 13
        contentItem: Body { text: choice.text; verticalAlignment: Text.AlignVCenter }
        background: Rectangle {
            radius: 11
            color: choice.highlighted ? win.tint : "transparent"
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
            color: field.activeFocus ? win.tint : win.paper
            radius: 15
            border.color: field.activeFocus ? win.accent : win.rule
            Behavior on color { ColorAnimation { duration: win.motion } }
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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 244
            color: win.panel
            border.color: win.rule
            radius: 25
            Behavior on color { ColorAnimation { duration: win.motion } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Image { source: "app-icon.svg"; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
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
                        readonly property bool selected: backend.selected === modelData.key
                        onClicked: backend.select(modelData.key)
                        contentItem: Body {
                            text: (entry.modelData.depth ? "↳  " : "") + entry.modelData.name
                            font.weight: entry.selected ? Font.DemiBold : Font.Normal
                            color: entry.selected ? win.accentInk : win.ink
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Reveal { selected: entry.selected; hovered: entry.hovered; focused: entry.visualFocus }
                    }
                }
                Action {
                    Layout.fillWidth: true
                    text: "+ Набор"
                    onClicked: nameSheet.begin("new")
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }
                Action { Layout.fillWidth: true; text: "Настройки"; onClicked: settingsSheet.open() }
                Action { Layout.fillWidth: true; text: "О приложении"; onClicked: aboutSheet.open() }
            }
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 15
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: hero.implicitHeight + 44
                    color: win.tint
                    radius: 25
                    border.color: win.rule
                    Behavior on color { ColorAnimation { duration: win.motion } }
                    ColumnLayout {
                        id: hero
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 13
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
                                SoftMenu {
                                    id: groupMenu
                                    SoftMenuItem { text: "Переименовать"; onTriggered: nameSheet.begin("rename") }
                                    SoftMenuItem { text: "Удалить"; onTriggered: confirmGroup.open() }
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
                    }
                }
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
                        add: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: win.motion }
                                NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: win.motion; easing.type: Easing.OutCubic }
                            }
                        }
                        ScrollBar.vertical: ScrollBar { }
                        delegate: Rectangle {
                            id: card
                            required property int index
                            required property var modelData
                            width: cards.cellWidth - 10
                            height: cards.cellHeight - 10
                            radius: 22
                            scale: cardOpen.down && win.motion ? 0.98 : 1
                            Behavior on scale { NumberAnimation { duration: win.motion / 2; easing.type: Easing.OutCubic } }
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
                                    SoftMenu {
                                        id: resourceMenu
                                        SoftMenuItem {
                                            text: "Изменить"
                                            visible: card.modelData.kind !== "Приложение"
                                            height: visible ? implicitHeight : 0
                                            onTriggered: addSheet.beginEdit(card.index, card.modelData)
                                        }
                                        SoftMenuItem { text: "Убрать из темы"; onTriggered: backend.removeResource(card.index) }
                                    }
                                }
                            }
                        }
                    }

                    SequentialAnimation {
                        id: switchCards
                        PropertyAction { target: cards; property: "opacity"; value: win.motion ? 0.35 : 1 }
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

    Sheet {
        id: addSheet
        objectName: "addSheet"
        parent: Overlay.overlay
        x: parent.width - width - 18
        y: 18
        width: Math.min(520, parent.width - 40)
        height: parent.height - 36
        padding: 25
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: win.motion }
                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: win.motion; easing.type: Easing.OutCubic }
            }
        }
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

        contentItem: ColumnLayout {
            spacing: 16
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
            Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }

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
                spacing: 7
                model: addSheet.matches
                ScrollBar.vertical: ScrollBar { }
                delegate: CheckDelegate {
                    id: appEntry
                    required property var modelData
                    width: ListView.view.width
                    height: 52
                    text: modelData.name
                    checked: addSheet.picked.includes(modelData.target)
                    leftPadding: 13
                    rightPadding: 13
                    onClicked: addSheet.toggle(modelData.target)
                    indicator: Item { width: 0; height: 0 }
                    contentItem: RowLayout {
                        spacing: 12
                        Rectangle {
                            Layout.preferredWidth: 29; Layout.preferredHeight: 29
                            radius: 9
                            color: appEntry.checked ? win.accentInk : win.tint
                            Behavior on color { ColorAnimation { duration: win.motion } }
                            Body {
                                anchors.centerIn: parent
                                text: appEntry.text.slice(0, 1).toUpperCase()
                                color: appEntry.checked ? win.accent : win.ink
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                        Body {
                            Layout.fillWidth: true
                            text: appEntry.text
                            color: appEntry.checked ? win.accentInk : win.ink
                        }
                        Rectangle {
                            Layout.preferredWidth: 22; Layout.preferredHeight: 22
                            radius: 11
                            color: appEntry.checked ? win.accentInk : "transparent"
                            border.color: appEntry.checked ? win.accentInk : win.muted
                            Body { anchors.centerIn: parent; text: "✓"; color: win.accent; visible: appEntry.checked }
                        }
                    }
                    background: Reveal { selected: appEntry.checked; hovered: appEntry.hovered; focused: appEntry.visualFocus }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: win.rule; visible: !addSheet.manual }
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

            RowLayout {
                Layout.fillWidth: true
                visible: addSheet.manual
                Repeater {
                    model: addSheet.manualTypes
                    Action {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        text: modelData
                        primary: manualKind.currentIndex === index
                        leftPadding: 8
                        rightPadding: 8
                        onClicked: manualKind.currentIndex = index
                    }
                }
            }
            QtObject {
                id: manualKind
                property int currentIndex: 0
                readonly property string currentText: addSheet.manualTypes[currentIndex]
            }
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

    Sheet {
        id: settingsSheet
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 460
        contentItem: ColumnLayout {
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Body { Layout.fillWidth: true; text: "Настройки"; font.family: win.serif; font.pixelSize: 33 }
                Action { text: "×"; Accessible.name: "Закрыть настройки"; onClicked: settingsSheet.close() }
            }
            Body { text: "Оформление"; font.weight: Font.DemiBold }
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: [{name: "Светлое", key: "light"}, {name: "Тёмное", key: "dark"}, {name: "Системное", key: "system"}]
                    Action {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.name
                        primary: backend.appearance === modelData.key
                        onClicked: backend.setAppearance(modelData.key)
                    }
                }
            }
            Body { text: "Акцент"; font.weight: Font.DemiBold }
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: win.accentNames
                    Action {
                        id: swatch
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        text: modelData
                        Accessible.description: backend.accent === index ? "Выбранный акцент" : ""
                        leftPadding: 8
                        rightPadding: 8
                        contentItem: Body {
                            text: swatch.text
                            color: win.accentInk
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.weight: backend.accent === swatch.index ? Font.Bold : Font.Normal
                        }
                        background: Rectangle {
                            radius: 15
                            color: win.accents[swatch.index]
                            border.width: backend.accent === swatch.index || swatch.visualFocus ? 2 : 0
                            border.color: win.accentInk
                        }
                        onClicked: backend.setAccent(index)
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }
            RowLayout {
                Layout.fillWidth: true
                Body { Layout.fillWidth: true; text: "Анимации" }
                Action {
                    text: backend.motion ? "Включены" : "Выключены"
                    primary: backend.motion
                    onClicked: backend.setMotion(!backend.motion)
                }
            }
        }
    }

    Sheet {
        id: aboutSheet
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 460
        contentItem: ColumnLayout {
            spacing: 15
            RowLayout {
                Layout.fillWidth: true
                Image { source: "app-icon.svg"; Layout.preferredWidth: 55; Layout.preferredHeight: 55 }
                ColumnLayout {
                    Layout.fillWidth: true
                    Body { Layout.fillWidth: true; text: "Верни рабочий стол"; font.family: win.serif; font.pixelSize: 24 }
                    Body { text: "Версия " + backend.version; color: win.muted }
                }
                Action { text: "×"; Accessible.name: "Закрыть информацию"; onClicked: aboutSheet.close() }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }
            Body { text: "Файл рабочих наборов"; font.weight: Font.DemiBold }
            TextEdit {
                Layout.fillWidth: true
                color: win.muted
                text: backend.dataPath
                textFormat: TextEdit.PlainText
                font.pixelSize: 13
                wrapMode: TextEdit.WrapAnywhere
                readOnly: true
                selectByMouse: true
            }
            Action {
                text: "Релизы на GitHub"
                onClicked: Qt.openUrlExternally("https://github.com/mihailmoskalenko08-eng/desktop-restore/releases")
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
        background: Rectangle { color: win.dark ? "#f2e6f9" : "#302342"; radius: 14 }
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
