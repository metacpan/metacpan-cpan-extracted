import perl
#if perl.MULTI_PERL:
#	print "1..0"
#	raise SystemExit

print "1..6"

perl.eval("use lib 't'")     # good when running from ..
perl.eval("use TestClass")

obj = perl.callm("new", "TestClass")

print obj
print type(obj)
print repr(obj)

# Test plain method calls

if obj.foo(42) != None: print "not",
print "ok 1"

if obj.foo() != 42: print "not",
print "ok 2"

my_dict = {}
obj.foo(my_dict)

if obj.foo() is not my_dict: print "not",
print "ok 3"

obj.foo(obj.newhash("key", 42))
try:
	obj.dump()
except perl.PerlError, v:
	print v

if int(obj.hash_deref(obj.foo(), "key")) != 42: print "not",
print "ok 4"

# calling in scalar/array context
print obj.localtime()
print obj.localtime_tuple()
print "----"

# callin back to python
class Foo:
	def foo(self, a):
		print "method foo called with argument", a
		return 12/a
	pass

p_obj = Foo()
x = obj.callback(p_obj, "foo", 3)
if x != 4: print "not",
print "ok 5"

try:
   obj.callback(p_obj, "foo", 0)
except ZeroDivisionError, v:
   if str(v) != "integer division or modulo": print "not",
   print "ok 6"


