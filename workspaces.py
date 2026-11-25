"""Local workspace storage and resource launching."""

import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import webbrowser
from pathlib import Path
from urllib.parse import urlsplit
from uuid import uuid4


RESOURCE_TYPES = ("Сайт", "Папка", "Файл", "Программа")


def new_group(name):
    return {"id": uuid4().hex, "name": name, "items": [], "topics": []}


def data_file():
    local_data = os.environ.get("LOCALAPPDATA")
    base = Path(local_data) if local_data else Path.home() / ".local" / "share"
    return base / "DesktopRestore" / "workspaces.json"


def existing_program(path):
    if path.is_file():
        return path
    found = shutil.which(str(path))
    if not found:
        raise ValueError("Программа не найдена. Выбери её через «Обзор».")
    return Path(found)


def validate_target(kind, target):
    if not target:
        raise ValueError("Укажи адрес или путь.")
    if kind == "Сайт":
        address = urlsplit(target)
        if address.scheme not in ("https", "http") or not address.hostname:
            raise ValueError("Укажи полный адрес сайта, начиная с https:// или http://.")
    elif kind in RESOURCE_TYPES:
        path = Path(os.path.expandvars(target)).expanduser()
        if kind == "Папка" and not path.is_dir():
            raise ValueError("Папка не найдена.")
        if kind == "Файл" and not path.is_file():
            raise ValueError("Файл не найден.")
        return existing_program(path) if kind == "Программа" else path
    else:
        raise ValueError("Неизвестный тип ресурса.")


def launch(item):
    kind, target = item["kind"], item["target"]
    path = validate_target(kind, target)
    if kind == "Сайт":
        if not webbrowser.open(target, new=2):
            raise OSError("Не удалось открыть браузер.")
        return

    path = path.resolve()
    if sys.platform == "win32":
        if kind == "Программа":
            os.startfile(str(path), "open", arguments=item.get("arguments", ""), cwd=str(path.parent))
        else:
            os.startfile(str(path))
    elif kind == "Программа":
        subprocess.Popen([str(path), *shlex.split(item.get("arguments", ""))], cwd=path.parent)
    else:
        subprocess.Popen(["open" if sys.platform == "darwin" else "xdg-open", str(path)])


class WorkspaceStore:
    def __init__(self, path):
        self.path = path

    def load(self):
        if not self.path.exists():
            groups = [new_group("Учёба"), new_group("Код")]
            return {"version": 1, "selected": groups[0]["id"], "groups": groups}

        with self.path.open(encoding="utf-8") as stream:
            data = json.load(stream)
        seen = set()
        if not isinstance(data, dict) or data.get("version") != 1:
            raise ValueError("Неизвестный формат файла рабочих наборов.")
        if not isinstance(data.get("selected"), (str, type(None))):
            raise ValueError("В файле сохранён неверный выбор рабочего набора.")
        self._validate_groups(data.get("groups"), seen)
        return data

    def _validate_groups(self, groups, seen):
        if not isinstance(groups, list):
            raise ValueError("В файле отсутствует список рабочих наборов или тем.")
        for group in groups:
            if not isinstance(group, dict):
                raise ValueError("Повреждён рабочий набор или тема.")
            group_id = group.get("id")
            if not isinstance(group_id, str) or not group_id or group_id in seen:
                raise ValueError("Повреждён идентификатор рабочего набора.")
            seen.add(group_id)
            if not isinstance(group.get("name"), str) or not isinstance(group.get("items"), list):
                raise ValueError("Повреждено название или список ресурсов.")
            for item in group["items"]:
                if not (
                    isinstance(item, dict)
                    and item.get("kind") in RESOURCE_TYPES
                    and isinstance(item.get("name"), str)
                    and isinstance(item.get("target"), str)
                    and isinstance(item.get("arguments", ""), str)
                ):
                    raise ValueError("Повреждён ресурс рабочего набора.")
            self._validate_groups(group.get("topics"), seen)

    def save(self, data):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", dir=self.path.parent, delete=False
            ) as stream:
                temporary = Path(stream.name)
                json.dump(data, stream, ensure_ascii=False, indent=2)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, self.path)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
