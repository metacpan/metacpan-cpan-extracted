# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Tie::Array::FileWriter;
ok(1); # If we made it this far, we're ok.

#########################

my @foo;

tie @foo, 'Tie::Array::FileWriter', "foo.dat", '%', '|';

push @foo, [ qw(a b c d) ];
push @foo, [ qw(e f g h) ];

undef @foo;
untie @foo;

open FOO, "foo.dat" or die "Could not open file 'foo.dat' for reading: $!";
my $temp = <FOO>;
close FOO;
unlink("foo.dat");

ok($temp, 'a%b%c%d|e%f%g%h|');

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

