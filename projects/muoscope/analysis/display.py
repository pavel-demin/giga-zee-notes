import os
import sys
import struct

from functools import partial

import matplotlib

matplotlib.use("Qt5Agg")

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

from PyQt5.QtWidgets import QLabel, QSpinBox


def display(f, ax, entry):
    w = 10
    l = 160
    h = [0, 50, 100, 400, 450, 500]

    f.seek(16 + (entry - 1) * 16)
    event = f.read(16)
    rpc, time = struct.unpack("QQ", event)
    laser = time & 1
    trig = (time >> 1) & 1
    time = time >> 2

    ax.cla()

    for i in range(64):
        layer = i // 16 + 1
        strip = i % 16
        x = [0, l, l, 0]
        y = [strip * w + 1, strip * w + 1, strip * w + w - 1, strip * w + w - 1]
        z = [h[layer], h[layer], h[layer], h[layer]]
        if layer % 2:
            v = [list(zip(x, y, z))]
            if rpc >> i & 1:
                ax.add_collection3d(Poly3DCollection(v, facecolors="b", alpha=0.5))
            else:
                ax.add_collection3d(Poly3DCollection(v, facecolors="y", alpha=0.1))
        else:
            v = [list(zip(y, x, z))]
            if rpc >> i & 1:
                ax.add_collection3d(Poly3DCollection(v, facecolors="r", alpha=0.5))
            else:
                ax.add_collection3d(Poly3DCollection(v, facecolors="y", alpha=0.1))

    for i in range(2):
        layer = i * 5
        x = [0, l, l, 0]
        y = [0, 0, l, l]
        z = [h[layer], h[layer], h[layer], h[layer]]
        v = [list(zip(y, x, z))]
        if trig:
            ax.add_collection3d(Poly3DCollection(v, facecolors="r", alpha=0.1))
        else:
            ax.add_collection3d(Poly3DCollection(v, facecolors="y", alpha=0.1))

    ax.set_xlim(0, l)
    ax.set_ylim(0, l)
    ax.set_zlim(0, 500)
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Z")
    ax.figure.canvas.draw()


if len(sys.argv) < 2:
    print("Usage: display.py input_file")
    sys.exit(1)

try:
    f = open(sys.argv[1], "rb")
except (OSError, IOError) as e:
    print("Cannot open input file")
    sys.exit(1)

f.seek(0, os.SEEK_END)
size = f.tell() - 16

fig = plt.figure(figsize=[8, 6], constrained_layout=True)

ax = fig.add_subplot(projection="3d")

toolbar = fig.canvas.toolbar
toolbar.addSeparator()
label = QLabel("Event")
event = QSpinBox()
event.valueChanged.connect(partial(display, f, ax))
event.setRange(1, size // 16)
toolbar.addWidget(label)
toolbar.addWidget(event)

plt.show()
