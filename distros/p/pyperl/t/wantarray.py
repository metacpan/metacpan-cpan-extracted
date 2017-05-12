import perl
#if perl.MULTI_PERL:
#	print "1..0"
#	raise SystemExit

print "1..11"


perl.eval("""

sub foo {
    if (wantarray) {
	return "array";
    }
    elsif (defined wantarray) {
        return "scalar";
    }
    else {
        return;
    }
}

""")

foo = perl.eval("\&foo")

testno = 1

def expect(res, expect):
    global testno
    if res != expect:
	print "Expected", repr(expect), "got", repr(res)
	print "not",
    print "ok", testno
    testno = testno + 1

void   = None
scalar = "scalar"
array  = ("array",)

expect(foo(), scalar)
expect(foo(__wantarray__ = 1), array)
expect(foo(__wantarray__ = None), void)

foo.__wantarray__ = 1;
expect(foo(), array)
expect(foo(__wantarray__ = 0), scalar)

expect(foo(__wantarray__ = None), void)

foo.__wantarray__ = None
expect(foo(), void)

expect(perl.call("foo"), scalar)
expect(perl.call_tuple("foo"), array)

expect(perl.call("foo", __wantarray__ = 1), array)
expect(perl.call_tuple("foo", __wantarray__ = 0), scalar)
