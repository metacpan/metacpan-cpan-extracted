# -*-perl-*-

use strict;
use Test::Legacy qw($ntest plan ok $TESTOUT $TESTERR);
use vars qw($mycnt);

# onfail() is run but is not passed anything.
BEGIN { plan test => 7, onfail => \&myfail, todo => [(2,3,4,5,6,7)] }

$mycnt = 0;

my $why = "zero != one";
# sneak in a test that Test::Harness wont see
open J, ">junk" || ok(0);
$TESTOUT = *J{IO};
$TESTERR = *J{IO};
ok(0, 1, $why);
$TESTOUT = *STDOUT{IO};
$TESTERR = *STDERR{IO};
close J;
unlink "junk";

sub myfail {
    my ($f) = @_;

    $ntest = 1;

    ok(1);      # check that onfail was called.

    ok(@$f, 1);

    my $t = $$f[0];
    ok($$t{diagnostic}, $why);
    ok($$t{'package'}, 'main');
    ok($$t{repetition}, 1);
    ok($$t{result}, 0);
    ok($$t{expected}, 1);
}
