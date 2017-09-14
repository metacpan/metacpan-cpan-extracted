use strict;
use warnings;

use Test::More 0.88; # done_testing
use DateTime ();

use WWW::Salesforce;

my $test_time = time;
my $tm = DateTime->from_epoch(epoch=>$test_time);

{
    my $dt = $tm->clone();
    $dt->set_time_zone('local');
    my $sf_date = WWW::Salesforce->sf_date($test_time);
    is($sf_date, $dt->strftime(q(%FT%T.%3N%z)), 'sf_date: current local');
}

# Timezones from http://science.ksc.nasa.gov/software/winvn/userguide/3_1_4.htm
my @places = (
    'Australia/Sydney',
    'America/Chicago',
    'Canada/Newfoundland',
    'Australia/Adelaide',
    'Pacific/Chatham',
);

foreach my $place (@places) {
    $ENV{TZ} = $place;
    my $dt = $tm->clone();
    $dt->set_time_zone($place);
    my $sf_date = WWW::Salesforce->sf_date($test_time);
    is($sf_date, $dt->strftime(q(%FT%T.%3N%z)), 'Checking ' . $place . ' time');
}

done_testing();
