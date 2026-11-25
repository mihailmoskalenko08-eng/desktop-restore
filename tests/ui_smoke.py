"""Exercise the real Qt interface with an isolated workspace and mock launch calls."""

from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from PySide6.QtCore import QObject, QSettings, Qt, QUrl, qInstallMessageHandler
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication

from app import Controller, VERSION
from workspaces import WorkspaceStore


def run():
    QQuickStyle.setStyle("Basic")
    qt = QApplication([])
    messages = []
    qInstallMessageHandler(lambda _type, _context, message: messages.append(message))
    with TemporaryDirectory() as folder:
        QSettings.setDefaultFormat(QSettings.Format.IniFormat)
        QSettings.setPath(QSettings.Format.IniFormat, QSettings.Scope.UserScope, folder)
        store = WorkspaceStore(Path(folder) / "workspaces.json")
        data = store.load()
        data["groups"][0]["items"] = [
            {"kind": "Сайт", "name": "Расписание", "target": "https://example.com/schedule"},
            {"kind": "Сайт", "name": "Конспект", "target": "https://example.com/notes"},
        ]
        store.save(data)
        backend = Controller(store, store.load())
        backend.receive_apps([{"name": "Редактор", "target": "Test.Editor"}], "")
        engine = QQmlApplicationEngine()
        engine.setInitialProperties({"backend": backend})
        qml = Path(__file__).resolve().parents[1] / "Main.qml"
        engine.load(QUrl.fromLocalFile(str(qml)))
        (window,) = engine.rootObjects()
        QTest.qWait(250)

        def click_item(item):
            point = item.mapToScene(item.boundingRect().center()).toPoint()
            QTest.mouseClick(window, Qt.MouseButton.LeftButton, Qt.KeyboardModifier.NoModifier, point)

        def visible_items():
            pending = [window.contentItem()]
            while pending:
                item = pending.pop()
                if item.isVisible():
                    yield item
                    pending.extend(item.childItems())

        def visible_text(text):
            return next(item for item in visible_items() if item.width() > 0 and item.property("text") == text)

        def click(text):
            click_item(visible_text(text))
            QTest.qWait(240)

        def contrast(foreground, background):
            def luminance(shade):
                def linear(value):
                    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
                return sum(weight * linear(channel) for weight, channel in zip(
                    (0.2126, 0.7152, 0.0722), shade.getRgbF()[:3]
                ))
            low, high = sorted((luminance(foreground), luminance(background)))
            return (high + 0.05) / (low + 0.05)

        def expect_text_contrast(button):
            label = button.property("contentItem")
            surface = button.property("background")
            assert contrast(label.property("color"), surface.property("color")) >= 4.5

        primary = next(item for item in visible_items() if item.property("text") == "Открыть всё"
                       and item.property("primary"))
        backend.setMotion(False)
        for appearance in ("dark", "light"):
            backend.setAppearance(appearance)
            for value in ("#000000", "#ffffff", "#777777", "#07368f", "#fce2a2"):
                backend.chooseColor(value)
                expect_text_contrast(primary)
                assert contrast(window.property("muted"), window.property("paper")) >= 4.5
                assert contrast(window.property("muted"), window.property("panel")) >= 4.5
            backend.select(data["groups"][1]["id"])
            assert not primary.isEnabled()
            expect_text_contrast(primary)
            backend.select(data["groups"][0]["id"])
        backend.setAccent(0)
        backend.setMotion(True)

        search = window.findChild(QObject, "resourceSearch")
        QTest.keyClick(window, Qt.Key.Key_K, Qt.KeyboardModifier.ControlModifier)
        assert search.hasActiveFocus()
        search.setProperty("text", "конспект")
        assert visible_text("Найдено: 1")
        with patch("app.launch") as launch:
            QTest.keyClick(window, Qt.Key.Key_Return)
            launch.assert_called_once_with(data["groups"][0]["items"][1])
        QTest.keyClick(window, Qt.Key.Key_Escape)
        assert search.property("text") == ""

        click("Настройки")
        swatches = {item.objectName(): item for item in visible_items() if item.objectName().startswith("accent-")}
        assert len(swatches) == 12
        assert {(swatch.width(), swatch.height()) for swatch in swatches.values()} == {(45.0, 45.0)}
        for swatch in swatches.values():
            sample = swatch.property("contentItem")
            assert sample.width() == sample.height() == 35
        click_item(swatches["accent-11"])
        assert backend.accent == 11
        click("Тёмное")
        assert backend.dark
        click("Свой цвет…")
        hex_input = window.findChild(QObject, "accentHex")
        assert hex_input.hasActiveFocus()
        pad = next(item for item in visible_items() if item.objectName() == "colorPad")
        previous_hex = hex_input.property("text")
        click_item(pad)
        assert hex_input.property("text") != previous_hex
        click("Отмена")
        assert backend.accent == 11

        click("Свой цвет…")
        def paste_hex(value):
            hex_input.forceActiveFocus()
            qt.clipboard().setText(value)
            QTest.keyClick(window, Qt.Key.Key_A, Qt.KeyboardModifier.ControlModifier)
            QTest.keyClick(window, Qt.Key.Key_V, Qt.KeyboardModifier.ControlModifier)

        paste_hex("#B0")
        assert not visible_text("Применить").isEnabled()
        paste_hex("#EC7010")
        preview = next(item for item in visible_items() if item.objectName() == "accentPreview")
        assert preview.property("color").name() == "#ec7010", (hex_input.property("text"), preview.property("color").name(), messages)
        click("Применить")
        assert backend.accent == -1 and backend.customColor == "#ec7010"
        persisted = Controller(store, store.load())
        assert persisted.dark and persisted.customColor == "#ec7010"
        QTest.keyClick(window, Qt.Key.Key_Escape)
        QTest.qWait(240)
        click("О приложении")
        assert visible_text(f"Версия {VERSION}")
        QTest.keyClick(window, Qt.Key.Key_Escape)
        QTest.qWait(240)

        click("+ Добавить")
        delegate = next(item for item in visible_items() if item.objectName() == "catalogRow")
        fill = next(item for item in visible_items() if item.objectName() == "selectionFill"
                    and item.parentItem() == delegate.property("background"))
        assert fill.width() == 0
        click_item(delegate)
        QTest.qWait(65)
        assert 0 < fill.width() < delegate.width()
        QTest.qWait(380)
        assert fill.width() == delegate.width()
        click("Добавить выбранные · 1")
        assert store.load()["groups"][0]["items"][-1]["target"] == "Test.Editor"
        window.close()
        del engine
    assert not messages, messages


if __name__ == "__main__":
    run()
    print("Qt smoke test passed")
