import sys
import struct
import matplotlib.pyplot as plt
import numpy as np

if len(sys.argv) != 3:
    print("Usage: histograms.py input_file output_file")
    sys.exit(1)

try:
    f = open(sys.argv[1], "rb")
except (OSError, IOError) as e:
    print("Cannot open input file")
    sys.exit(1)

# read header

header = f.read(16)

# read events and fill arrays

hits_per_layer = [[[], []] for _ in range(4)]
hits_per_strip = [[] for _ in range(4)]
timing = [[[], [], []] for _ in range(4)]
distance = [[] for _ in range(4)]

total = 0
hits = [[] for _ in range(4)]

while event := f.read(16):
    rpc, time = struct.unpack("QQ", event)
    laser = time & 1
    trig = (time >> 1) & 1
    time = time >> 2

    if trig:
        start = time
        total += 1
        first = [0 for _ in range(4)]
        second = [0 for _ in range(4)]
        hits = [[] for _ in range(4)]
        hits_per_layer[1].append(1)

    time -= start

    for i in range(64):
        if rpc >> i & 1 == 0:
            continue
        layer = i // 16
        strip = i % 16
        if first[layer] == 0:
            first[layer] = time
            timing[layer][0].append(time)
        elif first[layer] != time and second[layer] == 0:
            second[layer] = time
            timing[layer][1].append(time)
            timing[layer][2].append(time - first[layer])
        hits[layer].append(strip)
        hits_per_strip[layer].append(strip)

    if time == 249:
        for layer in range(4):
            h = hits[layer]
            if not h:
                continue
            distance[layer].append(np.ptp(h))
            hits_per_layer[layer][0].append(len(h))

# draw histograms

fig = plt.figure(figsize=[10, 6], dpi=160, constrained_layout=True)

gs = fig.add_gridspec(2, 3, figure=fig, wspace=0.05, hspace=0.1)

ax1 = fig.add_subplot(gs[0, 0])
ax2 = fig.add_subplot(gs[0, 1])
ax3 = fig.add_subplot(gs[0, 2])
ax4 = fig.add_subplot(gs[1, 0])
ax5 = fig.add_subplot(gs[1, 1])
ax6 = fig.add_subplot(gs[1, 2])

labels = ["A", "B", "C", "D"]

bins = range(-1, 19)

for layer in range(0, 4):
    h1, b1 = np.histogram(hits_per_layer[layer][0], bins=bins)
    ax1.step(b1[:-1], h1 / total * 100, where="post")

    h2, b2 = np.histogram(distance[layer], bins=bins)
    ax2.step(b2[:-1], h2 / total * 100, where="post")

    h3, b3 = np.histogram(hits_per_strip[layer], bins=bins)
    ax3.step(b3[:-1], h3 / total * 100, where="post")

    h4, b4 = np.histogram(timing[layer][0], bins=range(120, 142))
    ax4.step(b4[:-1] * 5, h4 / total * 100, where="post")

    h5, b5 = np.histogram(timing[layer][1], bins=range(120, 142))
    ax5.step(b5[:-1] * 5, h5 / total * 100, where="post")

    h6, b6 = np.histogram(timing[layer][2], bins=range(0, 22))
    ax6.step(b6[:-1] * 5, h6 / total * 100, where="post")

ax1.set_yscale("log")
ax1.set_ylim(0.1, 100)
ax1.set_xlim(-1, 17)
ax1.grid(True)
ax1.legend(labels)
ax1.set_xlabel("hits per layer")
ax1.set_ylabel("%")

ax2.set_yscale("log")
ax2.set_ylim(0.1, 100)
ax2.set_xlim(-1, 17)
ax2.grid(True)
ax2.legend(labels)
ax2.set_xlabel("distance from max to min strip")
ax2.set_ylabel("%")

ax3.set_yscale("log")
ax3.set_ylim(0.1, 100)
ax3.set_xlim(-1, 17)
ax3.grid(True)
ax3.legend(labels)
ax3.set_xlabel("RPC strip")
ax3.set_ylabel("hits per strip")

ax4.set_yscale("log")
ax4.set_ylim(0.1, 100)
ax4.grid(True)
ax4.legend(labels)
ax4.set_xlabel("time of first hit, ns")
ax4.set_ylabel("%")

ax5.set_yscale("log")
ax5.set_ylim(0.1, 100)
ax5.grid(True)
ax5.legend(labels)
ax5.set_xlabel("time of second hit, ns")
ax5.set_ylabel("%")

ax6.set_yscale("log")
ax6.set_ylim(0.1, 100)
ax6.grid(True)
ax6.legend(labels)
ax6.set_xlabel("time from first to second hit, ns")
ax6.set_ylabel("%")

fig.savefig(sys.argv[2])

plt.show()
