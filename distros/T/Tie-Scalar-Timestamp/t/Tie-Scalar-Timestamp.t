# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-Scalar-Timestamp.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('Tie::Scalar::Timestamp') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

tie my $timestamp, 'Tie::Scalar::Timestamp';
isa_ok(tied($timestamp), 'Tie::Scalar::Timestamp');

is($Tie::Scalar::Timestamp::DEFAULT_STRFTIME, '%Y-%m-%dT%H:%M:%S', 'Default strftime pattern is ISO8601');

my $stamp1 = $timestamp;
sleep 1;
my $stamp2 = $timestamp;

isnt($stamp1, $stamp2, 'Different timestamps should not match');


eval { $timestamp = '2004' };   # this should die
like($@, qr/Can't store/, "Assigning to timestamp should die");


tied($timestamp)->{no_die} = 1;
eval { $^W = 0; $timestamp = '2004' };   # now this SHOULDN'T die
is($@, '', 'Option no_die stops death on assignment');
