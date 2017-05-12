print "1..8"

import perl

# try to use perl as a simple calculator
if not perl.eval("3+3") == 6: print "not",
print "ok 1"

# can we pass strings back
if not perl.eval("substr('abcd', 0, 3)") == "abc": print "not",
print "ok 2"

# can we pass hashes both ways
if perl.MULTI_PERL:
    print "actually skipping test 3..."
    print "ok 3"
else:
    perl.eval("sub foo_elem { shift->{foo} }")
    hash = perl.eval("{ foo => 42 }")

    if not perl.call("foo_elem", hash) == 42: print "not",
    print "ok 3"

# try to trap exceptions
try:
	perl.eval("die 'Oops!'")
except perl.PerlError, val:
	if str(val)[:5] != "Oops!": print "not",
	print "ok 4" 

try:
	perl.call("not_there", 3, 4)
except perl.PerlError, val:
	if str(val) != "Undefined subroutine &main::not_there called.\n":
		print "not",
	print "ok 5"


# try calling perl function in array and scalar context

# first define a function
perl.eval("""
   sub foo2 {
	wantarray ? (1, 2, 3) : 42;
   }
""")

# scalar context
if perl.call("foo2") != 42: print "not",
print "ok 6"

# array context (tuple back)
res = perl.call_tuple("foo2")
if len(res) != 3 or res[0] != 1 or res[1] != 2 or res[2] != 3: print "not",
print "ok 7"


# can we call anonymous perl functions
# can we pass hashes both ways
if perl.MULTI_PERL:
    print "actually skipping test 8..."
    print "ok 8"
else:
    func = perl.eval("sub { $_[0] + $_[1] }")
    if int(func(3, 4)) != 7: print "not",
    print "ok 8"
