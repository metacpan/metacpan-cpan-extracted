#!//usr/bin/env python

import os
import sys

if sys.platform == 'win32':
	print os.path.join(sys.prefix, 'include')
else:
	print os.path.join(sys.prefix, 'include', 'python' + sys.version[:3])
