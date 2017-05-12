# Verify that perl executes concurrently as it should under MULTI_PERL

import perl
if not perl.MULTI_PERL:
        print "1..0"
        raise SystemExit

print "1..3"

import perl
import re

perl.eval("""
#line 14 "safecall"

#$^W = 1;
require Opcode;

sub compile {
    my($code) = @_;

    $code = "package main; sub do { " . $code . "}";
    #print "[[$code]]\\n";

    eval $code;
    die if $@;
}

sub foo { 42; }

*Safe1::_compile = \&compile;
""")

mask = perl.call("Opcode::opset", "bless", "add")
print perl.call_tuple("Opcode::opset_to_ops", mask)

perl.safecall("Safe1", mask, ('_compile', 'my $n = shift; print "ok $n\\n";'))
perl.safecall("Safe1", mask, ('do', 1))

# try a trapped opcode
try:
    perl.safecall("Safe1", mask, ('_compile', 'return bless {}, "Foo"'))
except perl.PerlError, v:
    #print v
    if not re.match('^bless trapped by operation mask', str(v)): print "not ",
    print "ok 2"

# The following call reset the perl parser state enought to
# avoid the 'nexttoke' bug.
perl.eval(""" sub ffff {}""")

perl.eval("""
sub foo {
    print "not ";
    Safe1::foo(@_);
}

sub Safe1::foo {
    my $n = shift;
    print "ok $n\\n";
}

""")


perl.safecall("Safe1", mask, ('_compile',
			      'foo(shift)'))
perl.safecall("Safe1", mask, ('do', 3))
