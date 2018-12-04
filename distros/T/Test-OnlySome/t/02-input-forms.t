#!perl
package t01;

use rlib 'lib';
use DTest;
use Test::OnlySome;

# Vars to hold the debug output from os(), since os() processing happens
# at compile time, and the stack trace doesn't point us here.
our ($t1, $t2, $t3, $t4);

my $hr = {foo => 'bar'};

os 't01::t1' $hr my $a1;
is($t1->{code}, 'my $a1;', 'os() grabs a statement');

os 't01::t2' $hr {my $a2; my $b2;};
is($t2->{code}, '{my $a2; my $b2;}', 'os() grabs a block');

BEGIN {
    eval { local $SIG{'__DIE__'}; os $hr my $a3; };
    ok(!$@, 'os() with statement, without debug, succeeded');
}

BEGIN {
    eval { local $SIG{'__DIE__'}; os $hr {my $a4; my $b4;}; };
    ok(!$@, 'os() with block, without debug, succeeded');
}

os 't01::t3' $hr 42 my $a5;
is($t3->{code}, 'my $a5;', 'os() grabs a statement after a number');
is($t3->{n}, '42', 'os() grabs a number before a statement');

os 't01::t4' $hr 1337 {my $a6; my $b6;};
is($t4->{code}, '{my $a6; my $b6;}', 'os() grabs a block after a number');
is($t4->{n}, '1337', 'os() grabs a number before a block');

# TODO figure out how to run these.  Currently, they abort the test despite
# the eval{}.
# See t/17*.t for thoughts that might help.  Maybe defer the croak() to the
# generated code?  Or File::Package?

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
