print "1..6"

import perl

class Foo:
    def foo(self, a, b=None):
        return "a=" + str(a) + ", b=" + str(b)

perl.eval("""

use Python qw(apply KW);

$| = 1;

sub foo {
    my $o = shift;

    eval {
        $o->foo();
    };
    #print $@;
    print "not " unless "$@" =~ /^python.exceptions.TypeError: not enough arguments/;
    print "ok 1\n";

    my $res;

    # Test glob version
    $res = $o->foo(101);
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=None";
    print "ok 2\n";

    {
       package Foo::Bar;
       $res = $o->foo(*b => 102, *a => 101);
       #print "$res\\n";
       print "not " unless $res eq "a=101, b=102";
       print "ok 3\n";
    }

    $res = $o->foo(101, *b => 102);
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=102";
    print "ok 4\n";

    # Test KW constructor
    $kw = KW(b => 102);
    $kw->{a} = 101;

    $res = $o->foo($kw);
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=102";
    print "ok 5\n";

    $res = $o->foo(KW(a => 101));
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=None";
    print "ok 6\n";
}

""")

perl.call("foo", Foo())


