import sys
from xreadlines import xreadlines

for line in xreadlines(sys.stdin):
    if line.startswith("%%BoundingBox:"):
        parts = line.split()
        x0, y0, x1, y1 = int(parts[1]), int(parts[2]), int(parts[3]), int(parts[4])
        x1 += x0
        y1 += y0
        x0 = 0
        y0 = 0
        line = "%%%%BoundingBox: %d %d %d %d\n" % (x0, y0, x1, y1)
    sys.stdout.write(line)
