#####################################################################
#
#  Test suite for 'Weather::Com::Simple'
#
#  Functional tests with 'Test::MockObject'. These could only be run
#  if Test::MockObject is installed.
#
#  Before `make install' is performed this script should be runnable
#  with `make test'. After `make install' it should work as
#  `perl t/Simple.t'
#
#####################################################################
#
# initialization
#
use Test::More tests => 8;
BEGIN { 
	use_ok('Weather::Com::DateTime');
};

my $testtime = 1109430000;

#####################################################################
#
# Testing object instantiation (do we use the right class)?
#
my $wc = Weather::Com::DateTime->new(-6);
$wc->set_lsup('02/25/05 11:21 PM Local Time');

isa_ok($wc, "Weather::Com::DateTime",    'Is a Weatcher::Com::DateTime object');

is($wc->time(),         "23:21",                    '24 hour time');
is($wc->time_ampm(),    "11:21 PM",                 'AM/PM mode');
is($wc->day(),          "25",                       'Day Number');
is($wc->mon(),          "02",                       'Number of month');
is($wc->year(),         "2005",                     'Year');
is(gmtime($wc->epoc()), 'Sat Feb 26 05:21:00 2005', 'GMTime');

