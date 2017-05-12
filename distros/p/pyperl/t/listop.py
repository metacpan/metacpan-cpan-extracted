import perl
#if perl.MULTI_PERL:
#	print "1..0"
#	raise SystemExit

print "1..16"

a = perl.get_ref("@")

if a.__type__ != 'ARRAY' or a.__class__ != None: print "not",
print "ok 1"

try:
	print a["foo"]
except TypeError, v:
	if str(v) != "perl array index must be integer": print "not",
	print "ok 2"

try:
	print a[10]
except IndexError, v:
        if str(v) != "perl array index out of range": print "not",
        print "ok 3"

try:
	a[4] = 5
except IndexError, v:
	if str(v) != "perl array assignment index out of range": print "not",
	print "ok 4"

a.extend(range(5))

a_copy = a[:]

if list(a) != range(5) or list(a) != list(a_copy): print "not",
print "ok 5"

a.append(2)

if a.index(2) != 2 or a.count(2) != 2 or a.count(99) != 0: print "not",
print "ok 6"

if a.pop() != 2 or len(a) != 5: print "not",
print "ok 7"

a.insert(0, "foo")
if a.pop(0) != "foo" or len(a) != 5: print "not",
print "ok 8"

a.append(3)
a.remove(3)
if len(a) != 5 or a.index(3) != 4: print "not",
print "ok 9"

a.remove(3)
try:
	a.remove(3)
except ValueError, v:
	if str(v) != "perlarray.remove(x): x not in list": print "not",
	print "ok 10"

try:
	print a.index(3)
except ValueError, v:
	if str(v) != "perlarray.index(x): x not in list": print "not",
	print "ok 11"

# restore list
a[3:3] = a_copy[3:4]

a.reverse()

if list(a) != range(4, -1, -1): print "not",
print "ok 12"

a.reverse()
if list(a) != range(5): print "not",
print "ok 13"

a.extend("abc")

if list(a) != range(5) + list("abc"): print "not",
print "ok 14"

a.extend(a)
if list(a) != (range(5) + list("abc"))*2: print "not",
print "ok 15"

a[5:] = perl.array([]);
if list(a) != range(5): print "not",
print "ok 16"
