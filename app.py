"""Qt Quick interface and bridge to the local workspace store."""

import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from pathlib import Path

from PySide6.QtCore import QObject, Property, QSettings, Qt, QUrl, Signal, Slot
from PySide6.QtGui import QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtWidgets import QApplication, QFileDialog, QMessageBox

from workspaces import WorkspaceStore, data_file, launch, new_group, validate_target


def start_apps():
    if sys.platform != "win32":
        return []
    command = (
        "[Console]::OutputEncoding = [Text.Encoding]::UTF8; "
        "$ErrorActionPreference = 'Stop'; "
        "Get-StartApps | Sort-Object Name | Select-Object Name, AppID | ConvertTo-Json -Compress"
    )
    result = subprocess.run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", command],
        capture_output=True, encoding="utf-8", errors="replace", check=True, timeout=20,
        creationflags=subprocess.CREATE_NO_WINDOW,
    )
    entries = json.loads(result.stdout or "[]") or []
    if isinstance(entries, dict):
        entries = [entries]
    unique = {}
    for row in entries:
        name, target = row.get("Name"), row.get("AppID")
        if name and target:
            unique.setdefault(target.casefold(), {"name": name, "target": target})
    return list(unique.values())


VERSION = "0.4.1"


class Controller(QObject):
    changed = Signal()
    structureChanged = Signal()
    settingsChanged = Signal()
    toast = Signal(str)
    appsChanged = Signal()
    discoveryDone = Signal(list, str)

    def __init__(self, store, data):
        super().__init__()
        self.store, self.data = store, data
        self.settings = QSettings("DesktopRestore", "DesktopRestore")
        legacy = "dark" if self.settings.value("dark", False, type=bool) else "light"
        self._appearance = self.settings.value("appearance", legacy, type=str)
        self._accent = max(-1, min(11, self.settings.value("accent", 0, type=int)))
        self._custom_color = self.settings.value("customColor", "#7568da", type=str)
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", self._custom_color):
            self._custom_color = "#7568da"
        self._motion = self.settings.value("motion", True, type=bool)
        QApplication.styleHints().colorSchemeChanged.connect(self.settingsChanged)
        self._apps, self._app_status = [], ""
        self._loaded = False
        self._pool = ThreadPoolExecutor(max_workers=1)
        self.discoveryDone.connect(self.receive_apps, Qt.ConnectionType.QueuedConnection)

    def entries(self):
        def walk(groups, parents=()):
            for group in groups:
                trail = (*parents, group["name"])
                yield groups, group, trail
                yield from walk(group["topics"], trail)
        return list(walk(self.data["groups"]))

    def current(self):
        selected = self.data.get("selected")
        entries = self.entries()
        return next((entry for entry in entries if entry[1]["id"] == selected),
                    entries[0] if entries else ([], None, ()))

    @Property("QVariantList", notify=structureChanged)
    def groups(self):
        return [{"key": group["id"], "name": group["name"], "depth": len(trail) - 1}
                for _, group, trail in self.entries()]

    @Property(str, notify=changed)
    def selected(self):
        group = self.current()[1]
        return group["id"] if group else ""

    @Property(str, notify=changed)
    def title(self):
        trail = self.current()[2]
        return trail[-1] if trail else "Рабочие наборы"

    @Property(str, notify=changed)
    def trail(self):
        return "  /  ".join(self.current()[2][:-1])

    @Property("QVariantList", notify=changed)
    def resources(self):
        group = self.current()[1]
        return group["items"] if group else []

    @Property(bool, notify=settingsChanged)
    def dark(self):
        if self._appearance == "system":
            return QApplication.styleHints().colorScheme() == Qt.ColorScheme.Dark
        return self._appearance == "dark"

    @Property(str, notify=settingsChanged)
    def appearance(self):
        return self._appearance

    @Property(int, notify=settingsChanged)
    def accent(self):
        return self._accent

    @Property(str, notify=settingsChanged)
    def customColor(self):
        return self._custom_color

    @Property(bool, notify=settingsChanged)
    def motion(self):
        return self._motion

    @Property(str, constant=True)
    def version(self):
        return VERSION

    @Property(str, constant=True)
    def dataPath(self):
        return str(self.store.path)

    @Property("QVariantList", notify=appsChanged)
    def apps(self):
        return self._apps

    @Property(str, notify=appsChanged)
    def appStatus(self):
        return self._app_status

    def save(self, previous, message="", *, structure=False):
        try:
            self.store.save(self.data)
        except OSError as error:
            self.data = previous
            self.toast.emit(f"Не удалось сохранить. {error}")
            return False
        if structure:
            self.structureChanged.emit()
        self.changed.emit()
        if message:
            self.toast.emit(message)
        return True

    @Slot(str)
    def setAppearance(self, value):
        if value in ("light", "dark", "system"):
            self._appearance = value
            self.settings.setValue("appearance", value)
            self.settingsChanged.emit()

    @Slot(int)
    def setAccent(self, value):
        if 0 <= value <= 11:
            self._accent = value
            self.settings.setValue("accent", value)
            self.settingsChanged.emit()

    @Slot(str)
    def chooseColor(self, value):
        if re.fullmatch(r"#[0-9a-fA-F]{6}", value):
            self._accent = -1
            self._custom_color = value.lower()
            self.settings.setValue("accent", -1)
            self.settings.setValue("customColor", self._custom_color)
            self.settingsChanged.emit()

    @Slot(bool)
    def setMotion(self, value):
        self._motion = value
        self.settings.setValue("motion", value)
        self.settingsChanged.emit()

    @Slot(str)
    def select(self, key):
        if key != self.selected and any(group["id"] == key for _, group, _ in self.entries()):
            previous = deepcopy(self.data)
            self.data["selected"] = key
            self.save(previous)

    @Slot(str, str, result=bool)
    def groupAction(self, mode, name):
        name = name.strip()
        group = self.current()[1]
        if not name or (mode in ("rename", "topic") and not group):
            return False
        previous = deepcopy(self.data)
        if mode == "rename":
            group["name"] = name
        else:
            new = new_group(name)
            target = group["topics"] if mode == "topic" else self.data["groups"]
            target.append(new)
            self.data["selected"] = new["id"]
        return self.save(previous, "Сохранено", structure=True)

    @Slot()
    def removeGroup(self):
        siblings, group, _ = self.current()
        if group:
            previous = deepcopy(self.data)
            siblings.remove(group)
            self.data["selected"] = self.selected or None
            self.save(previous, "Удалено из приложения", structure=True)

    @Slot()
    def loadApps(self):
        if self._loaded:
            return
        self._loaded = True
        self._app_status = "Ищу программы в меню «Пуск»…"
        self.appsChanged.emit()

        def discover():
            try:
                rows = start_apps()
                self.discoveryDone.emit(rows, "" if rows else "Программы из меню «Пуск» недоступны.")
            except (OSError, ValueError, subprocess.SubprocessError):
                self.discoveryDone.emit([], "Не удалось прочитать меню «Пуск». Можно добавить путь вручную.")
        self._pool.submit(discover)

    @Slot(list, str)
    def receive_apps(self, rows, status):
        self._apps, self._app_status = rows, status
        self._loaded = bool(rows)
        self.appsChanged.emit()

    @Slot("QVariantList", result=bool)
    def addApps(self, keys):
        return self.add_items([{"kind": "Приложение", **entry} for entry in self._apps if entry["target"] in keys])

    def add_items(self, items):
        group = self.current()[1]
        if not group:
            return False
        previous = deepcopy(self.data)
        before_count = len(group["items"])
        existing = {(item["kind"], item["target"].casefold()) for item in group["items"]}
        for item in items:
            key = item["kind"], item["target"].casefold()
            if key not in existing:
                group["items"].append(item)
                existing.add(key)
        count = len(group["items"]) - before_count
        if not count:
            self.toast.emit("Уже добавлено")
            return True
        return self.save(previous, f"Добавлено: {count}")

    @Slot(int, str, str, str, str, result=bool)
    def saveResource(self, index, kind, name, target, arguments):
        group = self.current()[1]
        if not group:
            return False
        target = target.strip().strip('"') if kind != "Сайт" else target.strip()
        try:
            validate_target(kind, target)
        except (OSError, ValueError) as error:
            self.toast.emit(str(error))
            return False
        fallback = target if kind == "Сайт" else (Path(target).stem or target)
        item = {"kind": kind, "name": name.strip() or fallback, "target": target}
        if kind == "Программа":
            item["arguments"] = arguments.strip()
        if index < 0:
            return self.add_items([item])
        previous = deepcopy(self.data)
        group["items"][index] = item
        return self.save(previous, "Ресурс изменён")

    @Slot(str, result=str)
    def browse(self, kind):
        if kind == "Папка":
            return QFileDialog.getExistingDirectory(None, "Выбери папку")
        file_filter = "Программы (*.exe *.lnk);;Все файлы (*)" if kind == "Программа" else "Все файлы (*)"
        return QFileDialog.getOpenFileName(None, "Выбери файл", "", file_filter)[0]

    @Slot("QVariantList")
    def dropFiles(self, urls):
        items = []
        for value in urls:
            path = Path(QUrl(value).toLocalFile())
            if not QUrl(value).isLocalFile() or not path.exists():
                continue
            kind = "Папка" if path.is_dir() else "Файл"
            if path.is_file() and path.suffix.lower() in (".exe", ".lnk"):
                kind = "Программа"
            items.append({"kind": kind, "name": path.name, "target": str(path)})
        if items:
            self.add_items(items)

    @Slot(int)
    def removeResource(self, index):
        previous = deepcopy(self.data)
        self.current()[1]["items"].pop(index)
        self.save(previous, "Убрано из темы")

    @Slot(int)
    def openResources(self, index):
        items = self.resources if index < 0 else self.resources[index:index + 1]
        failures = []
        for item in items:
            try:
                launch(item)
            except (OSError, ValueError) as error:
                failures.append(f"{item['name']} — {error}")
        if failures:
            QMessageBox.warning(None, "Некоторые ресурсы не открылись", "\n".join(failures))
        self.toast.emit(f"Открыто: {len(items) - len(failures)} из {len(items)}")


def main():
    QQuickStyle.setStyle("Basic")
    app = QApplication(sys.argv)
    app.setApplicationName("Верни рабочий стол")
    app.setApplicationVersion(VERSION)
    asset_root = Path(__file__).resolve().parent
    app.setWindowIcon(QIcon(str(asset_root / "app-icon.svg")))
    store = WorkspaceStore(data_file())
    try:
        data = store.load()
    except (OSError, ValueError) as error:
        QMessageBox.critical(None, "Не удалось открыть рабочие наборы", f"{store.path}\n\n{error}")
        return 1
    controller = Controller(store, data)
    engine = QQmlApplicationEngine()
    engine.setInitialProperties({"backend": controller})
    engine.load(QUrl.fromLocalFile(str(asset_root / "Main.qml")))
    if not engine.rootObjects():
        return 1
    if "--smoke-test" in sys.argv:
        app.processEvents()
        result = 0
    else:
        result = app.exec()
    del engine
    return result


if __name__ == "__main__":
    sys.exit(main())
