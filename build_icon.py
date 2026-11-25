"""Render the shared vector mark into a multi-resolution Windows icon."""

import struct
from pathlib import Path

from PySide6.QtCore import QBuffer, QIODevice, QRectF, Qt
from PySide6.QtGui import QImage, QPainter
from PySide6.QtSvg import QSvgRenderer
from PySide6.QtWidgets import QApplication


def main():
    app = QApplication([])
    source = Path(__file__).with_name("app-icon.svg")
    renderer = QSvgRenderer(str(source))
    if not renderer.isValid():
        raise ValueError(f"Invalid icon: {source}")
    sizes = (16, 24, 32, 48, 64, 128, 256)
    frames = []
    directory = []
    offset = 6 + 16 * len(sizes)
    for size in sizes:
        image = QImage(size, size, QImage.Format.Format_ARGB32_Premultiplied)
        image.fill(Qt.GlobalColor.transparent)
        painter = QPainter(image)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        renderer.render(painter, QRectF(0, 0, size, size))
        painter.end()
        buffer = QBuffer()
        buffer.open(QIODevice.OpenModeFlag.WriteOnly)
        if not image.save(buffer, "PNG"):
            raise RuntimeError("Could not encode the icon frame")
        frame = bytes(buffer.data())
        directory.append(struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(frame), offset))
        frames.append(frame)
        offset += len(frame)
    Path("app-icon.ico").write_bytes(struct.pack("<HHH", 0, 1, len(sizes)) + b"".join(directory + frames))


if __name__ == "__main__":
    main()
