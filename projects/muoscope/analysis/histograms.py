import sys
import struct
import matplotlib.pyplot as plt

if len(sys.argv) < 2:
    print("Usage: histograms.py input_file")
    sys.exit(1)

try:
    f = open(sys.argv[1], "rb")
except (OSError, IOError) as e:
    print("Cannot open input file")
    sys.exit(1)

# read events and fill arrays

hits_per_layer = [[] for _ in range(6)]
hits_per_strip = [[] for _ in range(6)]
hits_per_second = [[] for _ in range(6)]

while event := f.read(16):
    rpc, time = struct.unpack("QQ", event)
    pmt = time & 3
    time = time >> 2

    ns = [0] * 6

    for i in range(64):
        if rpc >> i & 1 == 0:
            continue
        layer = i // 16
        strip = i % 16
        ns[layer] += 1

    for i in range(2):
        if pmt >> i & 1 == 0:
            continue
        layer = 4 + i
        ns[layer] += 1

    # select events
    if ns[4] != 1 or ns[5] != 1:
        continue

    # hits per detector layer
    for i in range(6):
        hits_per_layer[i].append(ns[i])

    # hits per strip and hits per second
    for i in range(64):
        if rpc >> i & 1 == 0:
            continue
        layer = i // 16
        strip = i % 16
        hits_per_strip[layer].append(strip)
        hits_per_second[layer].append(time / 2.0e8)

    for i in range(2):
        if pmt >> i & 1 == 0:
            continue
        layer = 4 + i
        hits_per_second[layer].append(time / 2.0e8)

# draw histograms

fig = plt.figure(figsize=[10, 5], dpi=160, constrained_layout=True)

gs = fig.add_gridspec(2, 2, figure=fig, wspace=0.05, hspace=0.1)

ax1 = fig.add_subplot(gs[0, 0])
ax2 = fig.add_subplot(gs[0, 1])
ax3 = fig.add_subplot(gs[1, :])

labels = ["A", "B", "C", "D", "E", "F"]

bins = range(17)

for i in range(6):
    ax1.hist(hits_per_layer[i], bins=bins, histtype="step", label=labels[i])
    ax2.hist(hits_per_strip[i], bins=bins, histtype="step", label=labels[i])

ax1.grid(True)
ax1.legend()
ax1.set_xlabel("hits per detector layer")
ax1.set_ylabel("events")

ax2.grid(True)
ax2.legend()
ax2.set_xlabel("strip")
ax2.set_ylabel("hits per strip")

bins = range(601)

for i in range(6):
    ax3.hist(hits_per_second[i], bins=bins, histtype="step", label=labels[i])

ax3.grid(True)
ax3.legend()
ax3.set_xlabel("time, seconds")
ax3.set_ylabel("hits per second")

fig.savefig("histograms.pdf")

plt.show()
