# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('Tie::Array::Unique') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

tie my(@x), 'Tie::Array::Unique', (1 .. 5, 3 .. 7);
ok("@x" eq "1 2 3 4 5 6 7", "initialization");

push @x, 6 .. 9;
ok("@x" eq "1 2 3 4 5 6 7 8 9", "pushing");

unshift @x, -2 .. 3;
ok("@x" eq "-2 -1 0 1 2 3 4 5 6 7 8 9", "unshifting");

pop @x;
ok("@x" eq "-2 -1 0 1 2 3 4 5 6 7 8", "popping");

shift @x;
ok("@x" eq "-1 0 1 2 3 4 5 6 7 8", "shifting");

splice @x, 3, 2, (7,8,10,2);
ok("@x" eq "-1 0 1 10 2 4 5 6 7 8", "splicing");

@x = (1 .. 5);
ok("@x" eq "1 2 3 4 5", "clear/set");

$x[2] = 5;
ok("@x" eq "1 2 5 4", "setting");

$x[2] = 7;
ok("@x" eq "1 2 7 4", "setting");

push @x, 5;
ok("@x" eq "1 2 7 4 5", "pushing");

$x[3] = 7;
ok("@x" eq "1 2 7 5", "setting");

tie my(@y), 'Tie::Array::Unique',
  Tie::Array::Unique::How->new(sub { lc $_[0] } );

@y = qw( thiS );
ok("@y" eq "thiS", "folding");

@y = qw( thiS This THIS tHiS );
ok("@y" eq "thiS", "folding");

$y[0] = 'THis';
ok("@y" eq "THis", "folding");

