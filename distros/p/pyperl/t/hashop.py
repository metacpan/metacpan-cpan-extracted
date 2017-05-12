print "1..12"

import perl
h = perl.get_ref("%")

if h.__type__ != 'HASH' or h.__class__ != None: print "not ",
print "ok 1"

if len(h) != 0 or len(h.items()) != 0 or \
   len(h.keys()) != 0 or len(h.values()) != 0:
	print "not ",
print "ok 2"

try:
	print h[42]
except TypeError, v:
	if str(v) != 'perl hash key must be string': print "not ",
	print "ok 3"

try:
	print h["foo"]
except KeyError, v:
	if str(v) != "foo": print "not ",
	print "ok 4"

if h.get("foo") != None or h.get("foo", 42) != 42: print "not ",
print "ok 5"

try:
	print h.get(42)
except TypeError, v:
	if str(v) != "get, argument 1: expected read-only buffer, int found":
		print "not ",
	print "ok 6"

h["foo"] = 42

if len(h) != 1 or h["foo"] != 42: print "not ",
print "ok 7"

h["bar"] = 21

# here we assume a certain order, which might get broken by another hash
# algoritim or other internal changes.  In that case fix the tests below.
if h.keys() != ["foo", "bar"] or \
   h.values() != [42, 21] or \
   h.items() !=  [("foo", 42), ("bar", 21)]:
	print "not ",
print "ok 8"

if h.has_key("baz") or not h.has_key("bar"): print "not "
print "ok 9"

h2 = h.copy()
if id(h) == id(h2) or h.items() != h2.items(): print "not ",
print "ok 10"

h2.clear()
if len(h2) != 0: print "not "
print "ok 11"

del h["bar"]
if h.keys() != ["foo"]: print "not ",
print "ok 12"

