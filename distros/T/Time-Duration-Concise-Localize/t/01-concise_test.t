#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use Time::Duration::Concise;

my $min_tpc = 1.27;
eval "use Time::Seconds $min_tpc";
plan skip_all => "Time::Seconds $min_tpc required for testing" if $@;
plan tests => 27;

my $duration = Time::Duration::Concise->new(interval => '1d1.5h');

is($duration->interval, '1d1.5h', 'Interval');
is($duration->seconds,  91800,    'Seconds');
is(sprintf("%.2f", $duration->days),  1.06, 'Days');    # .3f fails on win32
is(sprintf("%.1f", $duration->hours), 25.5, 'Hours');
is($duration->minutes, 1530, 'Minutes');
is(sprintf("%.2f", $duration->weeks),                   0.15,   'Week');
is(sprintf("%.2f", $duration->months),                  0.03,   'Months');
is(sprintf("%.2f", $duration->minimum_number_of('mo')), '1.00', 'Minimum number of unit mo');
is($duration->as_concise_string,            '1d1h30m',                                'Concise string');
is($duration->as_concise_string(1),         '1d',                                     'Concise string');
is($duration->normalized_code,              '1530m',                                  'Normalized Code');
is(ref $duration->duration,                 'HASH',                                   'Duration');
is(ref $duration->duration_array,           'ARRAY',                                  'Duration Array');
is($duration->as_string,                    '1 day 1 hour 30 minutes',                'As string');
is($duration->as_string(1),                 '1 day',                                  'As string precision 1');
is($duration->as_string(2),                 '1 day 1 hour',                           'As string precision 2');
is($duration->as_string(3),                 '1 day 1 hour 30 minutes',                'As string precision 3');
is(scalar @{$duration->duration_array(3)},  '3',                                      'Duration array precision 3');
is(scalar @{$duration->duration_array(1)},  '1',                                      'Duration array precision 1');
is($duration->minimum_number_of('seconds'), 91800,                                    'Minimum number of seconds');
is($duration->minimum_number_of('s'),       91800,                                    'Minimum number of units');
is($duration->minimum_number_of('s'),       91800,                                    'Minimum number of units s');
is($duration->duration->{'time'}->pretty,   '1 days, 1 hours, 30 minutes, 0 seconds', 'Time::Seconds prettfies good');
is(ref $duration->get_time_layout(1),       'HASH',                                   'Got HASH Response');

subtest "concise format input require" => sub {
    plan tests => 1;
    my $duration;
    throws_ok { Time::Duration::Concise->new() } qr/Missing required arguments/, "missing required argument test";
};

subtest "general concise format check" => sub {
    plan tests => 3;
    my $duration;
    lives_ok { $duration = Time::Duration::Concise->new(interval => '1y1d1.5h') } "object initilized";
    throws_ok { $duration->seconds() } qr/Bad format supplied/, "concise format supplied wrong";
    throws_ok { $duration->minimum_number_of('p') } qr/Cannot determine period for p/, "wrong period";
};

subtest "existing object" => sub {
    plan tests => 3;
    my $duration = Time::Duration::Concise->new(interval => '1y1d1.5h');
    lives_ok { Time::Duration::Concise->new(interval => $duration) } "object with existing object";
    lives_ok { Time::Duration::Concise->new({interval => '1d2h'}) } "object with hash argument";
    throws_ok { Time::Duration::Concise->new({interval => ''}) } qr/Invalid time interval/, "invalid time interval";
};
