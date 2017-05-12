# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Test-MockObject-Chain.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Test::MockObject::Chain') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $fake = Test::MockObject::Chain->new();

$fake->test() = 20;
#my $result = $fake->test();
is($fake->test(), 20);

is($fake->test(2), undef);
$fake->test(2) = 4;
is($fake->test(2), 4);

$fake->test(3)->object_time(30) = 30;
is($fake->test(3)->object_time(30), 30);

my $user = Test::MockObject::Chain->new();
$user->orders()->find(newest => 1)->total_cost_in_pence() = 1000; 
is($user->orders()->find(newest => 1)->total_cost_in_pence(), 1000);

done_testing();