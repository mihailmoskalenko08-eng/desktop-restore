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
    readonly property color paper: dark ? "#141619" : "#f5f4f1"
    readonly property color panel: dark ? "#1c1f23" : "#fffefa"
    readonly property color sidebar: dark ? "#191b20" : "#efede8"
    readonly property color ink: dark ? "#f6f4f2" : "#22252b"
    readonly property color muted: dark ? "#bfc3cb" : "#575d69"
    readonly property color rule: dark ? "#3a3e46" : "#dad8d3"
    readonly property color disabledSurface: dark ? "#292d34" : "#eeece7"
    readonly property color disabledInk: dark ? "#aab1bd" : "#626873"
    readonly property var accentNames: ["Сирень", "Пудра", "Абрикос", "Мята", "Индиго", "Небо",
                                        "Бирюза", "Шалфей", "Мёд", "Коралл", "Слива", "Сланец"]
    readonly property var accents: ["#b9a3f4", "#e9a5c4", "#edb07f", "#83c6b5", "#7778dd", "#75ade9",
                                    "#48baaa", "#9abc76", "#e3bb61", "#e8867c", "#a477bf", "#8a9ab8"]
    readonly property color accent: backend.accent < 0 ? backend.customColor : accents[backend.accent]
    readonly property color primaryFill: dark ? Qt.tint("#c8c8d0", Qt.rgba(accent.r, accent.g, accent.b, 0.50))
                                             : Qt.tint("#292934", Qt.rgba(accent.r, accent.g, accent.b, 0.25))
    readonly property color accentInk: readableInk(primaryFill)
    readonly property color tint: Qt.tint(panel, Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.18 : 0.24))
    readonly property color selection: Qt.tint(panel, Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.29 : 0.40))
    font.family: Qt.platform.os === "windows" ? "Segoe UI" : Qt.application.font.family
    readonly property int motion: backend.motion ? 200 : 0
    readonly property int revealTime: backend.motion ? 330 : 0
    color: paper
    palette.window: panel
    palette.base: panel
    palette.text: ink
    palette.windowText: ink
    palette.button: panel
    palette.buttonText: ink
    palette.highlight: accent
    palette.highlightedText: readableInk(accent)
    Behavior on color { ColorAnimation { duration: win.motion } }

    function relativeLuminance(shade) {
        const linear = channel => channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4)
        return 0.2126 * linear(shade.r) + 0.7152 * linear(shade.g) + 0.0722 * linear(shade.b)
    }

    function readableInk(shade) {
        return relativeLuminance(shade) > 0.179 ? "#000000" : "#ffffff"
    }

    function hexColor(shade) {
        const code = channel => Math.round(channel * 255).toString(16).padStart(2, "0")
        return ("#" + code(shade.r) + code(shade.g) + code(shade.b)).toUpperCase()
    }

    component Body: Text {
        color: win.ink
        font.family: win.font.family
        font.pixelSize: 15
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }

    component Action: Button {
        id: action
        property bool primary: false
        readonly property color surface: !enabled ? win.disabledSurface
            : primary ? (down ? Qt.lighter(win.primaryFill, 1.13) : win.primaryFill)
                      : (down || hovered ? win.tint : win.panel)
        font.pixelSize: 15
        font.weight: Font.DemiBold
        leftPadding: 16
        rightPadding: 16
        topPadding: 9
        bottomPadding: 9
        scale: down && win.motion ? 0.972 : 1
        Behavior on scale { NumberAnimation { duration: win.motion / 2; easing.type: Easing.OutCubic } }
        contentItem: Body {
            text: action.text
            color: !action.enabled ? win.disabledInk : action.primary ? win.readableInk(actionBackground.color) : win.ink
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font: action.font
        }
        background: Rectangle {
            id: actionBackground
            radius: 9
            border.width: action.visualFocus || !action.primary || !action.enabled ? 1 : 0
            border.color: action.visualFocus ? win.ink : win.rule
            color: action.surface
            Behavior on color { ColorAnimation { duration: win.motion } }
        }
    }

    component Reveal: Item {
        id: reveal
        property bool selected: false
        property bool hovered: false
        property bool focused: false
        property bool framed: true
        Rectangle {
            anchors.fill: parent
            radius: 9
            color: reveal.hovered ? win.tint : reveal.framed ? win.panel : "transparent"
            border.width: reveal.framed || reveal.focused ? 1 : 0
            border.color: reveal.focused ? win.accent : win.rule
            Behavior on color { ColorAnimation { duration: win.motion } }
        }
        Rectangle {
            objectName: "selectionFill"
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: reveal.selected ? parent.width : 0
            opacity: width > 0 ? 1 : 0
            radius: Math.min(9, width / 2)
            color: win.selection
            Behavior on width { NumberAnimation { duration: win.revealTime; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: win.motion } }
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
        font.family: win.font.family
        placeholderTextColor: win.muted
        selectByMouse: true
        font.pixelSize: 15
        padding: 12
        background: Rectangle {
            color: field.activeFocus ? win.tint : win.paper
            radius: 10
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
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 228
            color: win.sidebar
            Behavior on color { ColorAnimation { duration: win.motion } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Image { source: "app-icon.svg"; Layout.preferredWidth: 28; Layout.preferredHeight: 28 }
                    Body { text: "Верни рабочий стол"; font.weight: Font.DemiBold }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }
                RowLayout {
                    Layout.fillWidth: true
                    Body { text: "Рабочие наборы"; color: win.muted; font.pixelSize: 14; Layout.fillWidth: true }
                    Action {
                        text: "+"; leftPadding: 9; rightPadding: 9
                        Accessible.name: "Создать набор"
                        onClicked: nameSheet.begin("new")
                    }
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 3
                    model: backend.groups
                    ScrollBar.vertical: ScrollBar { }
                    delegate: ItemDelegate {
                        id: entry
                        required property var modelData
                        width: ListView.view.width
                        height: 38
                        leftPadding: 10 + Math.min(modelData.depth, 5) * 12
                        rightPadding: 8
                        readonly property bool selected: backend.selected === modelData.key
                        onClicked: backend.select(modelData.key)
                        contentItem: Body {
                            text: (entry.modelData.depth ? "↳  " : "◇  ") + entry.modelData.name
                            font.weight: entry.selected ? Font.DemiBold : Font.Normal
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Reveal {
                            framed: false
                            selected: entry.selected
                            hovered: entry.hovered
                            focused: entry.visualFocus
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: win.rule }
                Action { Layout.fillWidth: true; text: "Настройки"; onClicked: settingsSheet.open() }
                Action { Layout.fillWidth: true; text: "О приложении"; onClicked: aboutSheet.open() }
            }
        }
        Rectangle { Layout.fillHeight: true; width: 1; color: win.rule }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property var entries: backend.resources.map((item, index) => ({ item, index }))
            readonly property var filtered: entries.filter(row =>
                (row.item.name + " " + row.item.target).toLocaleLowerCase().includes(resourceSearch.text.trim().toLocaleLowerCase()))

            Shortcut {
                sequence: "Ctrl+K"
                enabled: !addSheet.opened && !settingsSheet.opened && !aboutSheet.opened && !nameSheet.opened && !confirmGroup.opened
                onActivated: { resourceSearch.forceActiveFocus(); resourceSearch.selectAll() }
            }
            ColumnLayout {
                width: Math.min(parent.width - 62, 820)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 27
                anchors.bottomMargin: 24
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    Body { Layout.fillWidth: true; text: backend.trail || "Рабочие наборы"; color: win.muted; font.pixelSize: 14 }
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
                RowLayout {
                    Layout.fillWidth: true
                    Body {
                        Layout.fillWidth: true
                        text: backend.title
                        font.pixelSize: 36
                        font.weight: Font.DemiBold
                    }
                    Action { text: "+ Добавить"; enabled: backend.selected !== ""; onClicked: addSheet.begin() }
                    Action {
                        text: "Открыть всё"
                        primary: true
                        enabled: backend.resources.length > 0
                        onClicked: backend.openResources(-1)
                    }
                }

                Field {
                    id: resourceSearch
                    objectName: "resourceSearch"
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    leftPadding: 36
                    rightPadding: 76
                    placeholderText: "Поиск в этой теме"
                    Accessible.name: "Поиск в этой теме"
                    onAccepted: {
                        if (stage.filtered.length > 0 && text.trim())
                            backend.openResources(stage.filtered[0].index)
                    }
                    Keys.onEscapePressed: clear()
                    Body { text: "⌕"; color: win.muted; font.pixelSize: 23; x: 12; anchors.verticalCenter: parent.verticalCenter }
                    Action {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: resourceSearch.text ? "×" : "Ctrl+K"
                        topPadding: 4; bottomPadding: 4; leftPadding: 7; rightPadding: 7
                        Accessible.name: resourceSearch.text ? "Очистить поиск" : "Поиск"
                        onClicked: { resourceSearch.clear(); resourceSearch.forceActiveFocus() }
                    }
                }
                Body {
                    Layout.fillWidth: true
                    text: resourceSearch.text ? "Найдено: " + stage.filtered.length : "Ресурсы · " + stage.entries.length
                    color: win.muted
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Rectangle {
                        id: resourceSurface
                        width: parent.width
                        height: Math.min(parent.height, stage.filtered.length ? stage.filtered.length * 59 + 12 : 210)
                        radius: 14
                        color: win.panel
                        border.color: win.rule
                    }

                    ListView {
                        id: cards
                        anchors.fill: resourceSurface
                        anchors.margins: 7
                        clip: true
                        spacing: 2
                        model: stage.filtered
                        ScrollBar.vertical: ScrollBar { }
                        delegate: ItemDelegate {
                            id: card
                            required property var modelData
                            readonly property var resource: modelData.item
                            width: ListView.view.width
                            height: 57
                            leftPadding: 10
                            rightPadding: 12
                            Accessible.name: "Открыть " + resource.name
                            onClicked: backend.openResources(modelData.index)
                            background: Rectangle {
                                radius: 9
                                color: card.hovered || card.visualFocus ? win.tint : "transparent"
                                Behavior on color { ColorAnimation { duration: win.motion } }
                            }
                            contentItem: RowLayout {
                                spacing: 12
                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    radius: 9
                                    color: win.tint
                                    Body {
                                        anchors.centerIn: parent
                                        font.weight: Font.DemiBold
                                        text: ({"Сайт": "↗", "Папка": "▱", "Файл": "≡"})[card.resource.kind]
                                              || card.resource.name.slice(0, 1).toUpperCase()
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Body { Layout.fillWidth: true; text: card.resource.name; font.weight: Font.DemiBold }
                                    Body {
                                        Layout.fillWidth: true
                                        text: card.resource.kind === "Приложение" ? "Приложение из меню «Пуск»" : card.resource.target
                                        color: win.muted
                                        font.pixelSize: 14
                                    }
                                }
                                Body { text: card.resource.kind; color: win.muted; font.pixelSize: 14 }
                                Action {
                                    text: "⋯"; leftPadding: 8; rightPadding: 8
                                    Accessible.name: "Действия с ресурсом"
                                    onClicked: resourceMenu.popup()
                                    SoftMenu {
                                        id: resourceMenu
                                        SoftMenuItem {
                                            text: "Изменить"
                                            visible: card.resource.kind !== "Приложение"
                                            height: visible ? implicitHeight : 0
                                            onTriggered: addSheet.beginEdit(card.modelData.index, card.resource)
                                        }
                                        SoftMenuItem { text: "Убрать из темы"; onTriggered: backend.removeResource(card.modelData.index) }
                                    }
                                }
                            }
                        }
                    }
                    NumberAnimation {
                        id: switchCards
                        target: cards
                        property: "opacity"
                        from: win.motion ? 0.52 : 1
                        to: 1
                        duration: win.motion
                        easing.type: Easing.OutCubic
                    }
                    Connections {
                        target: backend
                        function onChanged() {
                            if (stage.lastTopic !== backend.selected) {
                                stage.lastTopic = backend.selected
                                resourceSearch.clear()
                                switchCards.restart()
                            }
                        }
                    }
                    ColumnLayout {
                        anchors.centerIn: resourceSurface
                        width: Math.min(resourceSurface.width - 32, 360)
                        spacing: 8
                        visible: stage.filtered.length === 0
                        Body {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: resourceSearch.text ? "Ничего не найдено" : backend.selected ? "В теме пока пусто" : "Создай рабочий набор"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                        Body {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: resourceSearch.text ? "Попробуй другое название или путь." : "Добавь программы, ссылки или перетащи сюда файлы."
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            color: win.muted
                        }
                        Action {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 8
                            visible: !resourceSearch.text
                            text: backend.selected ? "Добавить ресурс" : "Создать набор"
                            onClicked: backend.selected ? addSheet.begin() : nameSheet.begin("new")
                        }
                    }
                    DropArea {
                        anchors.fill: parent
                        enabled: backend.selected !== ""
                        onDropped: drop => { if (drop.hasUrls) backend.dropFiles(drop.urls) }
                        Rectangle {
                            anchors.fill: parent
                            visible: parent.containsDrag
                            color: win.tint
                            opacity: 0.6
                            border.color: win.accent
                            border.width: 2
                            radius: 14
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
                font.weight: Font.DemiBold; font.pixelSize: 28
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
            Body { text: "Удалить набор или тему?"; font.weight: Font.DemiBold; font.pixelSize: 24 }
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
                NumberAnimation { property: "x"; from: addSheet.parent.width - addSheet.width + 9
                                  to: addSheet.parent.width - addSheet.width - 18
                                  duration: win.motion; easing.type: Easing.OutCubic }
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
                    font.weight: Font.DemiBold; font.pixelSize: 32
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
                    objectName: "catalogRow"
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
                            color: appEntry.checked ? win.primaryFill : win.tint
                            Behavior on color { ColorAnimation { duration: win.motion } }
                            Body {
                                anchors.centerIn: parent
                                text: appEntry.text.slice(0, 1).toUpperCase()
                                color: appEntry.checked ? win.accentInk : win.ink
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }
                        Body {
                            Layout.fillWidth: true
                            text: appEntry.text
                            color: win.ink
                        }
                        Rectangle {
                            Layout.preferredWidth: 22; Layout.preferredHeight: 22
                            radius: 11
                            color: appEntry.checked ? win.primaryFill : "transparent"
                            border.color: appEntry.checked ? win.primaryFill : win.muted
                            Body { anchors.centerIn: parent; text: "✓"; color: win.accentInk; visible: appEntry.checked }
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
        opacity: colorSheet.visible ? 0 : 1
        Overlay.modal: Rectangle { color: colorSheet.visible ? "transparent" : "#55000000" }
        contentItem: ColumnLayout {
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                Body { Layout.fillWidth: true; text: "Настройки"; font.weight: Font.DemiBold; font.pixelSize: 33 }
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
                        Layout.preferredWidth: 0
                        primary: backend.appearance === modelData.key
                        onClicked: backend.setAppearance(modelData.key)
                    }
                }
            }
            Body { text: "Акцент"; font.weight: Font.DemiBold }
            GridLayout {
                id: colorGrid
                objectName: "colorGrid"
                Layout.alignment: Qt.AlignHCenter
                columns: 6
                columnSpacing: 13
                rowSpacing: 10
                Repeater {
                    model: win.accentNames
                    Button {
                        id: swatch
                        required property int index
                        required property string modelData
                        readonly property bool chosen: backend.accent === index
                        Layout.minimumWidth: 45
                        Layout.maximumWidth: 45
                        Layout.minimumHeight: 45
                        Layout.maximumHeight: 45
                        padding: 5
                        leftPadding: 5; rightPadding: 5; topPadding: 5; bottomPadding: 5
                        text: modelData
                        objectName: "accent-" + index
                        Accessible.name: "Цвет " + text
                        Accessible.description: chosen ? "Выбран" : ""
                        ToolTip.text: text
                        ToolTip.visible: hovered
                        ToolTip.delay: 400
                        background: Rectangle {
                            color: "transparent"
                            radius: width / 2
                            border.width: swatch.chosen || swatch.visualFocus || swatch.hovered ? 2 : 0
                            border.color: win.ink
                        }
                        contentItem: Rectangle {
                            radius: width / 2
                            color: win.accents[swatch.index]
                            scale: swatch.down && win.motion ? 0.9 : 1
                            Behavior on scale { NumberAnimation { duration: win.motion / 2 } }
                            Body {
                                anchors.centerIn: parent
                                text: "✓"
                                color: win.readableInk(win.accents[swatch.index])
                                visible: swatch.chosen
                                font.weight: Font.Bold
                            }
                        }
                        onClicked: backend.setAccent(index)
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                    radius: 8; color: win.accent; border.color: win.rule
                }
                Body {
                    Layout.fillWidth: true
                    text: backend.accent < 0 ? backend.customColor.toUpperCase() : win.accentNames[backend.accent]
                    color: win.muted
                }
                Action {
                    text: "Свой цвет…"
                    onClicked: colorSheet.begin()
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
        id: colorSheet
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 488
        z: 5
        property real hue: 0
        property real saturation: 0
        property real brightness: 0
        property bool writingHex: false
        readonly property color draft: Qt.hsva(hue, saturation, brightness, 1)
        readonly property bool validHex: /^#?[0-9a-fA-F]{6}$/.test(hexField.text)

        function begin() {
            setDraft(win.accent)
            hexField.text = win.hexColor(win.accent)
            open()
        }

        function setDraft(shade) {
            if (shade.hsvHue >= 0)
                hue = shade.hsvHue
            else if (!opened)
                hue = 0
            saturation = shade.hsvSaturation
            brightness = shade.hsvValue
        }

        function updateFromHex(value) {
            if (!writingHex && /^#?[0-9a-fA-F]{6}$/.test(value))
                setDraft(Qt.color(value.startsWith("#") ? value : "#" + value))
        }

        function syncHex() {
            writingHex = true
            hexField.text = win.hexColor(draft)
            writingHex = false
        }

        function acceptColor() {
            if (!validHex)
                return
            backend.chooseColor(hexField.text.startsWith("#") ? hexField.text : "#" + hexField.text)
            close()
        }

        onOpened: hexField.forceActiveFocus()
        contentItem: ColumnLayout {
            spacing: 15
            RowLayout {
                Layout.fillWidth: true
                Body { Layout.fillWidth: true; text: "Свой цвет"; font.pixelSize: 27; font.weight: Font.DemiBold }
                Action { text: "×"; Accessible.name: "Закрыть выбор цвета"; onClicked: colorSheet.close() }
            }

            Rectangle {
                id: colorArea
                objectName: "colorPad"
                Layout.fillWidth: true
                Layout.preferredHeight: 164
                color: win.rule
                radius: 10
                Item {
                    id: shadeArea
                    anchors.fill: parent
                    anchors.margins: 3
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#ffffff" }
                            GradientStop { position: 1; color: Qt.hsva(colorSheet.hue, 1, 1, 1) }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#00000000" }
                            GradientStop { position: 1; color: "#000000" }
                        }
                    }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        x: Math.max(0, Math.min(parent.width - width, colorSheet.saturation * parent.width - width / 2))
                        y: Math.max(0, Math.min(parent.height - height, (1 - colorSheet.brightness) * parent.height - height / 2))
                        color: "transparent"
                        border.color: "#ffffff"; border.width: 2
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 2
                            radius: width / 2; color: "transparent"; border.color: "#000000"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.CrossCursor
                        function pick(mouse) {
                            colorSheet.saturation = Math.max(0, Math.min(1, mouse.x / width))
                            colorSheet.brightness = 1 - Math.max(0, Math.min(1, mouse.y / height))
                            colorSheet.syncHex()
                        }
                        onPressed: mouse => pick(mouse)
                        onPositionChanged: mouse => { if (pressed) pick(mouse) }
                    }
                }
            }
            Slider {
                id: hueSlider
                objectName: "colorHue"
                Layout.fillWidth: true
                from: 0
                to: 0.999
                stepSize: 0.005
                value: colorSheet.hue
                Accessible.name: "Оттенок"
                onMoved: {
                    colorSheet.hue = value
                    colorSheet.syncHex()
                }
                background: Rectangle {
                    x: hueSlider.leftPadding
                    y: hueSlider.topPadding + (hueSlider.availableHeight - height) / 2
                    width: hueSlider.availableWidth
                    height: 10; radius: 5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#ff0000" }
                        GradientStop { position: 1 / 6; color: "#ffff00" }
                        GradientStop { position: 2 / 6; color: "#00ff00" }
                        GradientStop { position: 3 / 6; color: "#00ffff" }
                        GradientStop { position: 4 / 6; color: "#0000ff" }
                        GradientStop { position: 5 / 6; color: "#ff00ff" }
                        GradientStop { position: 1; color: "#ff0000" }
                    }
                }
                handle: Rectangle {
                    width: 20; height: 20; radius: 10
                    x: hueSlider.leftPadding + hueSlider.visualPosition * (hueSlider.availableWidth - width)
                    y: hueSlider.topPadding + (hueSlider.availableHeight - height) / 2
                    color: Qt.hsva(colorSheet.hue, 1, 1, 1)
                    border.color: hueSlider.activeFocus ? win.ink : win.panel
                    border.width: 3
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Body { text: "HEX-код"; color: win.muted }
                    Field {
                        id: hexField
                        objectName: "accentHex"
                        Layout.fillWidth: true
                        maximumLength: 7
                        placeholderText: "#7568DA"
                        Accessible.name: "HEX-код цвета"
                        onTextChanged: colorSheet.updateFromHex(text)
                        onAccepted: colorSheet.acceptColor()
                    }
                }
                Rectangle {
                    objectName: "accentPreview"
                    Layout.preferredWidth: 140; Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignBottom
                    radius: 10
                    color: colorSheet.draft
                    border.color: win.rule
                    Body { anchors.centerIn: parent; text: "Образец"; color: win.readableInk(parent.color); font.weight: Font.DemiBold }
                }
            }
            Body {
                visible: !colorSheet.validHex
                text: "Введи шесть цифр или букв A–F, например #7568DA."
                color: win.muted
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Action { text: "Отмена"; onClicked: colorSheet.close() }
                Action { text: "Применить"; primary: true; enabled: colorSheet.validHex; onClicked: colorSheet.acceptColor() }
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
                    Body { Layout.fillWidth: true; text: "Верни рабочий стол"; font.weight: Font.DemiBold; font.pixelSize: 24 }
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
                font.pixelSize: 14
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
