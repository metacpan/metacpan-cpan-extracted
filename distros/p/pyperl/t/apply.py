import perl
#if (perl.MULTI_PERL):
#    print "1..0"
#    raise SystemExit

print "1..14"

def ok(a, b=None):
    return "a=" + str(a) + ", b=" + str(b)

perl.eval("""

use Python qw(apply);

$| = 1;

sub {
    my $f = shift;

    # First some tests that are expected to blow up
    eval {
       apply($f);
    };
    #print $@;

    # XXX For some strange reason =~ is not to force $@ to stingify, so
    # I had to help it with "$@" =~.
    # Hmmm, something to fix some other time :-(
    print "not " unless "$@" =~ /^python\.exceptions\.TypeError: not enough arguments/;
    print "ok 1\n";

    eval {
       apply($f, undef);
    };
    #print $@;
    print "not " unless "$@" =~ /^python\.exceptions\.TypeError: not enough arguments/;
    print "ok 2\n";

    eval {
       apply($f, undef, undef);
    };
    #print $@;
    print "not " unless "$@" =~ /^python\.exceptions\.TypeError: not enough arguments/;
    print "ok 3\n";

    eval {
       apply($f, undef, undef, undef);
    };
    #print $@;
    print "not " unless "$@" =~ /^Too many arguments at/;
    print "ok 4\n";

    eval {
       apply($f, [1,2,3]);
    };
    #print $@;
    print "not " unless "$@" =~ /^python.exceptions.TypeError: too many arguments/;
    print "ok 5\n";

    eval {
       apply($f, [], {b => 2});
    };
    #print $@;
    print "not " unless "$@" =~ /^python.exceptions.TypeError: not enough arguments/;
    print "ok 6\n";

    eval {
       apply($f, [1], {a => 2});
    };
    #print $@;
    print "not " unless "$@" =~ /^python.exceptions.TypeError: keyword parameter redefined/;
    print "ok 7\n";

    eval {
       apply($f, [], {a => 2, b => 3, c => 4});
    };
    #print $@;
    print "not " unless "$@" =~ /^python.exceptions.TypeError: unexpected keyword argument: c/;
    print "ok 8\n";

    eval {
        apply($f, 1);
    };
    #print $@;
    print "not " unless "$@" =~ /^/;
    print "ok 9\n";

    # Then some tests that are expected to work
    $res = apply($f, undef, { a => 101, b => 102 });
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=102";
    print "ok 10\n";

    $res = apply($f, undef, { a => 101 });
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=None";
    print "ok 11\n";

    $res = apply($f, [101, 102]);
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=102";
    print "ok 12\n";

    $res = apply($f, Python::list(101, 102), Python::dict());
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=102";
    print "ok 13\n";

    $res = apply($f, [], Python::dict(a => 101));
    #print "$res\\n";
    print "not " unless $res eq "a=101, b=None";
    print "ok 14\n";

}


""")(ok)
