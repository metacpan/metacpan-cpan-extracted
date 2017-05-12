# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 6 ;
use Time::Elapse;
#$Time::Elapse::_DEBUG = 1;

ok(1, 'Module Loads OK'); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

Time::Elapse->lapse(my $now = 'processing');
sleep(1);
my $test1 = $now ;
ok( $test1 =~ /(\d\d:\d\d:\d\d\.\d+)\s+\[processing\]/, "$test1");
my $elapsed = $1 || '00:00:00.000000';

$now = 'halfway';
my $test2 = $now ;
ok( $test2  =~ /(\d\d:\d\d:\d\d\.\d+)\s+\[halfway\]/, "$test2");
my $elapsed2 = $1 || '00:00:00.000000';

ok( $elapsed2 lt $elapsed, "has time reset? is $elapsed2 earlier than $elapsed?");
sleep(2);
my $test3 = $now ;

ok( $test3  =~ /(\d\d:\d\d:\d\d\.\d+)\s+\[halfway\]/, "$test3");
my $elapsed3 = $1 || '00:00:00.000000';

ok( $elapsed2 lt $elapsed3, "has time passed? is $elapsed3 later than $elapsed2?");
