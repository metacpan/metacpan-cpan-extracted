use strict;
use warnings;

use Test::More;

my $min_tpc = 1.27;
eval "use Time::Seconds $min_tpc";
plan skip_all => "Time::Seconds $min_tpc required for testing" if $@;
plan tests => 120;

eval "use Test::NoWarnings";

use Time::Duration::Concise;

my %results = (
    day => {
        normalized_code   => '1d',
        as_concise_string => '1d',
        seconds           => 86400,
        minutes           => '1440.00',
        hours             => '24.00',
        days              => '1.0000',
    },
    pi_hour => {
        normalized_code   => '11304s',
        as_concise_string => '3h8m24s',
        seconds           => 11304,
        minutes           => '188.40',
        hours             => '3.14',
        days              => '0.1308',
    },
    e_minute => {
        normalized_code   => '162s',
        as_concise_string => '2m42s',
        seconds           => 162,
        minutes           => '2.70',
        hours             => '0.05',
        days              => '0.0019',
    },
    kibi_second => {
        normalized_code   => '1024s',
        as_concise_string => '17m4s',
        seconds           => 1024,
        minutes           => '17.07',
        hours             => '0.28',
        days              => '0.0119',
    },
);

my $newstyle_testcases = {
    day         => ['1d',    '24h',    '1440m',  '86400s', 86400, '23h60m', '1430m600s'],
    pi_hour     => ['3.14h', '3h8.4m', '11304s', '5m11004s'],
    e_minute    => ['2.71m', '1m102s', '3m-18s'],
    kibi_second => [1024,    '16m64s', '+10m+424s'],
};

foreach my $which (keys %{$newstyle_testcases}) {
    foreach my $time (@{$newstyle_testcases->{$which}}) {
        comparisons(Time::Duration::Concise->new(interval => $time), $which);
    }
}

sub comparisons {
    my ($ti_obj, $which) = @_;

    isa_ok($ti_obj, 'Time::Duration::Concise', 'Object creation for ' . $which);
    is($ti_obj->normalized_code,   $results{$which}->{'normalized_code'},   ' normalized_code match.');
    is($ti_obj->as_concise_string, $results{$which}->{'as_concise_string'}, ' as_concise_string match');
    is($ti_obj->seconds,           $results{$which}->{'seconds'},           ' seconds match.');
    is(sprintf("%.2f", $ti_obj->minutes), $results{$which}->{'minutes'}, ' minutes match.');
    is(sprintf("%.2f", $ti_obj->hours),   $results{$which}->{'hours'},   ' hours match.');
    is(sprintf("%.4f", $ti_obj->days),    $results{$which}->{'days'},    ' days match.');
}
