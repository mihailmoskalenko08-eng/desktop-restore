"""Desktop front end for «Верни рабочий стол»."""

import tkinter as tk
from copy import deepcopy
from tkinter import filedialog, messagebox, simpledialog, ttk

from workspaces import RESOURCE_TYPES, WorkspaceStore, data_file, launch, new_group, validate_target


class ResourceDialog(simpledialog.Dialog):
    def __init__(self, parent, item=None):
        self.initial = item or {"kind": "Сайт", "name": "", "target": ""}
        super().__init__(parent, "Редактировать ресурс" if item else "Добавить ресурс")

    def body(self, frame):
        self.kind = tk.StringVar(value=self.initial["kind"])
        self.name = tk.StringVar(value=self.initial["name"])
        self.target = tk.StringVar(value=self.initial["target"])
        self.arguments = tk.StringVar(value=self.initial.get("arguments", ""))
        frame.columnconfigure(1, weight=1)
        ttk.Label(frame, text="Тип").grid(row=0, column=0, sticky="w", padx=6, pady=6)
        kinds = ttk.Combobox(frame, state="readonly", values=RESOURCE_TYPES, textvariable=self.kind)
        kinds.grid(row=0, column=1, sticky="ew", padx=6, pady=6)
        kinds.bind("<<ComboboxSelected>>", self.update_browse)
        ttk.Label(frame, text="Название").grid(row=1, column=0, sticky="w", padx=6, pady=6)
        name = ttk.Entry(frame, textvariable=self.name, width=48)
        name.grid(row=1, column=1, sticky="ew", padx=6, pady=6)
        ttk.Label(frame, text="Адрес или путь").grid(row=2, column=0, sticky="w", padx=6, pady=6)
        ttk.Entry(frame, textvariable=self.target).grid(row=2, column=1, sticky="ew", padx=6, pady=6)
        self.browse_button = ttk.Button(frame, text="Обзор…", command=self.browse)
        self.browse_button.grid(row=2, column=2, padx=6, pady=6)
        self.arguments_label = ttk.Label(frame, text="Аргументы запуска")
        self.arguments_label.grid(row=3, column=0, sticky="w", padx=6, pady=6)
        self.arguments_entry = ttk.Entry(frame, textvariable=self.arguments)
        self.arguments_entry.grid(row=3, column=1, sticky="ew", padx=6, pady=6)
        self.update_browse()
        return name

    def buttonbox(self):
        buttons = ttk.Frame(self, padding=(12, 4, 12, 12))
        buttons.pack(fill="x")
        ttk.Button(buttons, text="Отмена", command=self.cancel).pack(side="right")
        ttk.Button(buttons, text="Сохранить", command=self.ok).pack(side="right", padx=6)
        self.bind("<Return>", self.ok)
        self.bind("<Escape>", self.cancel)

    def update_browse(self, _event=None):
        kind = self.kind.get()
        self.browse_button.configure(state="disabled" if kind == "Сайт" else "normal")
        for widget in (self.arguments_label, self.arguments_entry):
            if kind == "Программа":
                widget.grid()
            else:
                widget.grid_remove()

    def browse(self):
        kind = self.kind.get()
        if kind == "Папка":
            target = filedialog.askdirectory(parent=self)
        else:
            options = {}
            if kind == "Программа":
                options["filetypes"] = [("Программы и ярлыки", "*.exe *.lnk"), ("Все файлы", "*.*")]
            target = filedialog.askopenfilename(parent=self, **options)
        if target:
            self.target.set(target)

    def validate(self):
        try:
            validate_target(self.kind.get(), self.target.get().strip())
        except (ValueError, OSError) as error:
            messagebox.showwarning("Проверь ресурс", str(error), parent=self)
            return False
        return True

    def apply(self):
        target = self.target.get().strip()
        self.result = {"kind": self.kind.get(), "name": self.name.get().strip() or target, "target": target}
        if self.kind.get() == "Программа":
            self.result["arguments"] = self.arguments.get().strip()


class DesktopRestore:
    def __init__(self, root, store, data):
        self.root = root
        self.store = store
        self.data = data
        self.groups = {}
        self.selected_id = None
        self.root.title("Верни рабочий стол")
        self.root.geometry("1040x650")
        self.root.minsize(820, 480)
        self.build_ui()
        self.refresh_tree(self.data["selected"])
        self.root.bind("<Control-n>", lambda _event: self.add_group(False))

    def build_ui(self):
        style = ttk.Style(self.root)
        style.configure("Title.TLabel", font=("Segoe UI", 23, "bold"))
        style.configure("Section.TLabel", font=("Segoe UI", 14, "bold"))
        style.configure("Treeview", rowheight=30)

        header = ttk.Frame(self.root, padding=(24, 20, 24, 16))
        header.pack(fill="x")
        ttk.Label(header, text="Верни рабочий стол", style="Title.TLabel").pack(anchor="w")
        ttk.Label(header, text="Собери программы, файлы и сайты для каждого занятия.").pack(anchor="w", pady=(4, 0))

        panels = ttk.Panedwindow(self.root, orient="horizontal")
        panels.pack(fill="both", expand=True, padx=24)
        sidebar = ttk.Frame(panels, padding=(0, 0, 12, 0), width=275)
        content = ttk.Frame(panels, padding=(12, 0, 0, 0), width=560)
        panels.add(sidebar, weight=0)
        panels.add(content, weight=1)

        ttk.Label(sidebar, text="Рабочие наборы", style="Section.TLabel").pack(anchor="w", pady=(0, 10))
        groups = ttk.Frame(sidebar)
        groups.pack(fill="both", expand=True)
        self.tree = ttk.Treeview(groups, show="tree", selectmode="browse")
        self.tree.column("#0", width=245, minwidth=100, stretch=True)
        scroll = ttk.Scrollbar(groups, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scroll.set)
        scroll.pack(side="right", fill="y")
        self.tree.pack(side="left", fill="both", expand=True)
        self.tree.bind("<<TreeviewSelect>>", self.select_group)

        group_actions = ttk.Frame(sidebar)
        group_actions.pack(fill="x", pady=(10, 4))
        ttk.Button(group_actions, text="+ Набор", command=lambda: self.add_group(False)).pack(side="left")
        self.add_topic_button = ttk.Button(group_actions, text="+ Тема", command=lambda: self.add_group(True))
        self.add_topic_button.pack(side="left", padx=(6, 0))
        manage_groups = ttk.Frame(sidebar)
        manage_groups.pack(fill="x", pady=(0, 6))
        self.rename_button = ttk.Button(manage_groups, text="Переименовать", command=self.rename_group)
        self.rename_button.pack(side="left")
        self.delete_group_button = ttk.Button(manage_groups, text="Удалить", command=self.delete_group)
        self.delete_group_button.pack(side="left", padx=(6, 0))

        main_actions = ttk.Frame(content)
        main_actions.pack(fill="x", pady=(0, 10))
        self.open_all_button = ttk.Button(main_actions, text="Открыть всё", command=self.open_all)
        self.open_all_button.pack(side="right")
        self.heading = ttk.Label(main_actions, style="Section.TLabel")
        self.heading.pack(side="left", fill="x", expand=True, padx=(0, 6))
        self.hint = ttk.Label(content)
        self.hint.pack(anchor="w", pady=(0, 10))

        listing = ttk.Frame(content)
        listing.pack(fill="both", expand=True)
        self.resources = ttk.Treeview(listing, columns=("name", "kind", "target"), show="headings", selectmode="browse")
        for key, label, width in (
            ("name", "Название", 180), ("kind", "Тип", 100), ("target", "Адрес или путь", 280)
        ):
            self.resources.heading(key, text=label)
            self.resources.column(key, width=width, minwidth=60, stretch=key != "kind")
        scroll = ttk.Scrollbar(listing, command=self.resources.yview)
        self.resources.configure(yscrollcommand=scroll.set)
        scroll.pack(side="right", fill="y")
        self.resources.pack(side="left", fill="both", expand=True)
        self.resources.bind("<<TreeviewSelect>>", lambda _event: self.update_buttons())
        self.resources.bind("<Double-Button-1>", self.open_clicked_resource)
        self.resources.bind("<Return>", self.open_resource)

        resource_actions = ttk.Frame(content)
        resource_actions.pack(fill="x", pady=(10, 6))
        self.add_resource_button = ttk.Button(resource_actions, text="+ Ресурс", command=self.add_resource)
        self.open_resource_button = ttk.Button(resource_actions, text="Открыть", command=self.open_resource)
        self.edit_resource_button = ttk.Button(resource_actions, text="Изменить", command=self.edit_resource)
        self.delete_resource_button = ttk.Button(resource_actions, text="Удалить", command=self.delete_resource)
        for button in (
            self.add_resource_button, self.open_resource_button, self.edit_resource_button, self.delete_resource_button
        ):
            button.pack(side="left", padx=(0, 6))

        self.status = tk.StringVar()
        ttk.Label(self.root, textvariable=self.status, padding=(24, 8, 24, 12)).pack(fill="x")

    def refresh_tree(self, selected):
        self.groups.clear()
        self.tree.delete(*self.tree.get_children())

        def insert(groups, parent=""):
            for group in groups:
                group_id = group["id"]
                self.groups[group_id] = (groups, group)
                self.tree.insert(parent, "end", iid=group_id, text=group["name"], open=True)
                insert(group["topics"], group_id)

        insert(self.data["groups"])
        self.selected_id = selected if selected in self.groups else next(iter(self.groups), None)
        if self.selected_id:
            self.tree.selection_set(self.selected_id)
            self.tree.focus(self.selected_id)
            self.tree.see(self.selected_id)
        self.refresh_resources()

    def current_group(self):
        return self.groups[self.selected_id][1] if self.selected_id else None

    def select_group(self, _event):
        selected = self.tree.selection()
        if not selected or selected[0] == self.selected_id:
            return
        previous = deepcopy(self.data)
        self.selected_id = selected[0]
        self.commit(previous, "Последний выбор сохранён.")

    def refresh_resources(self):
        self.resources.delete(*self.resources.get_children())
        group = self.current_group()
        self.heading.configure(text=group["name"] if group else "Выбери набор")
        if group:
            for index, item in enumerate(group["items"]):
                self.resources.insert("", "end", iid=str(index), values=(item["name"], item["kind"], item["target"]))
        if group is None:
            hint = "Создай набор для учёбы, работы или личного проекта."
        elif not group["items"]:
            hint = "Добавь сайт, файл, папку или программу."
        else:
            hint = "Двойной щелчок открывает один ресурс."
        self.hint.configure(text=hint)
        self.update_buttons()

    def update_buttons(self):
        group = self.current_group()
        has_group = group is not None
        has_resource = bool(self.resources.selection())
        for widgets, enabled in (
            ((self.add_topic_button, self.rename_button, self.delete_group_button, self.add_resource_button), has_group),
            ((self.open_all_button,), has_group and bool(group["items"])),
            ((self.open_resource_button, self.edit_resource_button, self.delete_resource_button), has_resource),
        ):
            for widget in widgets:
                widget.configure(state="normal" if enabled else "disabled")

    def commit(self, previous, status, *, rebuild_tree=False):
        self.data["selected"] = self.selected_id
        try:
            self.store.save(self.data)
        except OSError as error:
            self.data = previous
            self.refresh_tree(previous["selected"])
            messagebox.showerror("Не удалось сохранить", str(error), parent=self.root)
            return
        if rebuild_tree:
            self.refresh_tree(self.selected_id)
        else:
            self.refresh_resources()
        self.status.set(status)

    def add_group(self, topic):
        parent = self.current_group()
        if topic and parent is None:
            return
        title = "Новая тема" if topic else "Новый набор"
        name = simpledialog.askstring(title, "Название", parent=self.root)
        if not name or not name.strip():
            return
        previous = deepcopy(self.data)
        group = new_group(name.strip())
        (parent["topics"] if topic else self.data["groups"]).append(group)
        self.selected_id = group["id"]
        self.commit(previous, "Добавлено.", rebuild_tree=True)

    def rename_group(self):
        group = self.current_group()
        name = simpledialog.askstring("Переименовать", "Название", initialvalue=group["name"], parent=self.root)
        if not name or not name.strip():
            return
        previous = deepcopy(self.data)
        group["name"] = name.strip()
        self.commit(previous, "Название изменено.", rebuild_tree=True)

    def delete_group(self):
        siblings, group = self.groups[self.selected_id]
        if not messagebox.askyesno(
            "Удалить из приложения", f"Удалить «{group['name']}» вместе с его темами и списками ресурсов?",
            parent=self.root,
        ):
            return
        previous = deepcopy(self.data)
        parent = self.tree.parent(self.selected_id)
        siblings.remove(group)
        self.selected_id = parent or None
        if not self.selected_id and self.data["groups"]:
            self.selected_id = self.data["groups"][0]["id"]
        self.commit(previous, "Удалено из приложения.", rebuild_tree=True)

    def resource_index(self):
        selection = self.resources.selection()
        return int(selection[0]) if selection else None

    def add_resource(self):
        group = self.current_group()
        item = ResourceDialog(self.root).result
        if item:
            previous = deepcopy(self.data)
            group["items"].append(item)
            self.commit(previous, "Ресурс добавлен.")

    def edit_resource(self):
        index = self.resource_index()
        if index is None:
            return
        items = self.current_group()["items"]
        item = ResourceDialog(self.root, items[index]).result
        if item:
            previous = deepcopy(self.data)
            items[index] = item
            self.commit(previous, "Ресурс изменён.")

    def delete_resource(self):
        index = self.resource_index()
        if index is None:
            return
        previous = deepcopy(self.data)
        self.current_group()["items"].pop(index)
        self.commit(previous, "Ресурс удалён из списка.")

    def open_clicked_resource(self, event):
        if self.resources.identify_row(event.y):
            self.open_resource()

    def open_resource(self, _event=None):
        index = self.resource_index()
        if index is not None:
            self.open_items([self.current_group()["items"][index]])

    def open_all(self):
        self.open_items(self.current_group()["items"])

    def open_items(self, items):
        failures = []
        for item in items:
            try:
                launch(item)
            except (OSError, ValueError) as error:
                failures.append(f"{item['name']} — {error}")
        self.status.set(f"Запущено: {len(items) - len(failures)} из {len(items)}.")
        if failures:
            messagebox.showwarning("Некоторые ресурсы не открылись", "\n".join(failures), parent=self.root)


def main():
    root = tk.Tk()
    store = WorkspaceStore(data_file())
    try:
        data = store.load()
    except (OSError, ValueError) as error:
        root.withdraw()
        messagebox.showerror("Не удалось открыть рабочие наборы", f"{store.path}\n\n{error}", parent=root)
        root.destroy()
        return
    DesktopRestore(root, store, data)
    root.mainloop()


if __name__ == "__main__":
    main()
