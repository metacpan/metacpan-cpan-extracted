# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Time::Tradedates;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


use Time::Local;

# test Feb 2004 leap year ending on Sunday
$et = timelocal( 0,0,0,1,1,2004);

$ret = getNumDays( $et );
print ( $ret == 29 ? "test 1: ok $ret\n" : "test 1: not ok $ret\n" );
    
$ret = lastTradeDay( 1, 2004, 0 );
print ( $ret == 27 ? "test 2: ok $ret\n" : "test 2: not ok $ret\n" );

$ret2 = lastTradeDay( 1, 2004, -1 );
print ( $ret2 <= $ret  ? "test 3: ok $ret2\n" : "test 3: not ok $ret2\n" );

# test Jun 2003 ends on Monday (the minus is the one to watch test 5)
$ret = lastTradeDay( 5, 2003, 0 );
print ( $ret == 30 ? "test 4: ok $ret\n" : "test 4: not ok $ret\n" );

$ret2 = lastTradeDay( 5, 2003, -1 );
print ( $ret2 == 27  ? "test 5: ok $ret2\n" : "test 5: not ok $ret2\n" );

$ret2 = lastTradeDay( 5, 2003, -3 );
print ( $ret2 == 0  ? "test 6: ok $ret2\n" : "test 6: not ok $ret2\n" );

$ret2 = firstTradeDay( 10, 2003 );
print ( $ret2 == 3  ? "test 7: ok $ret2\n" : "test 7: not ok $ret2\n" );
