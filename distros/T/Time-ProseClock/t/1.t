# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 7;
#BEGIN { use_ok('Time::ProseClock') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Test::Simple tests => 7;

use Time::ProseClock;

my $ptest = Time::ProseClock->new();

$ptest->_get_time(time);

ok( defined($ptest->{'time'}->{'hours'}) &&
    defined($ptest->{'time'}->{'hours'}), '_get_time()');

$ptest->_set_minute();
ok( length($ptest->{'min_phrase'}), '_set_minute()' );

$ptest->_set_hour();
ok( length($ptest->{'hour_phrase'}), '_set_hour()' );

$ptest->_set_phrases();
ok ( 5  == @{$ptest->{'MinutePhrases'}}, 'instantiate MinutePhrases' );
ok ( 24 == @{$ptest->{'HourPhrases'}}, 'instantiate HourPhrases' );
ok ( 12 == keys %{$ptest->{'Multiples'}}, 'instantiate Multiples' );

ok ( length($ptest->display()), 'display' );

exit;
