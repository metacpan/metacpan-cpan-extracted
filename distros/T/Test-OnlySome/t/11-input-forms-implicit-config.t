#!perl
package t11;

use rlib 'lib';
use DTest;
use Test::OnlySome;

# Vars to hold the debug output from os(), since os() processing happens
# at compile time, and the stack trace doesn't point us here.
our ($t1, $t2);

os 't11::t1' my $a1;
is($t1->{code}, 'my $a1;', 'os() grabs a statement');

os 't11::t2' {my $a2; my $b2;};
is($t2->{code}, '{my $a2; my $b2;}', 'os() grabs a block');

BEGIN {
    eval { local $SIG{'__DIE__'}; os my $a3; };
    ok(!$@, 'os() with statement, without debug, succeeded');
}

BEGIN {
    eval { local $SIG{'__DIE__'}; os {my $a4; my $b4;}; };
    ok(!$@, 'os() with block, without debug, succeeded');
}

# TODO figure out how to run these.  Currently, they abort the test despite
# the eval{}.

#BEGIN {
#    eval { local $SIG{'__DIE__'}; os @hr my $a5; };
#    ok($@, 'os() with statement, without debug, with wrong var, failed');
#}
#
#
#BEGIN {
#    eval { local $SIG{'__DIE__'}; os @hr {my $a6; my $b6;}; };
#    ok($@, 'os() with block, without debug, with wrong var, failed');
#}

done_testing();
