use strict;
use warnings;

use lib 't';

use Test::More;

my $min_tpc = 1.27;
eval "use Time::Seconds $min_tpc";
plan skip_all => "Time::Seconds $min_tpc required for testing" if $@;
plan tests => 17;

eval "use Test::NoWarnings";

use Time::Duration::Concise::Localize;

my %display_tests = (
    '1d' => {
        1 => '1 day',
        2 => '1 day',
        3 => '1 day',
        4 => '1 day',
    },
    '1h3m' => {
        1 => '1 hour',
        2 => '1 hour 3 minutes',
        3 => '1 hour 3 minutes',
        4 => '1 hour 3 minutes',
    },
    '1d34m12s' => {
        1 => '1 day',
        2 => '1 day 34 minutes',
        3 => '1 day 34 minutes 12 seconds',
        4 => '1 day 34 minutes 12 seconds',
    },
    '4d12h16m8s' => {
        1 => '4 days',
        2 => '4 days 12 hours',
        3 => '4 days 12 hours 16 minutes',
        4 => '4 days 12 hours 16 minutes 8 seconds',
        }

);

foreach my $code (sort keys %display_tests) {
    my %elements = %{$display_tests{$code}};
    my $ti       = Time::Duration::Concise::Localize->new(
        interval => $code,
        locale   => 'en',
    );
    foreach my $length (sort keys %elements) {
        is($ti->as_string($length), $elements{$length}, 'Display ' . $code . ' of length ' . $length . ' is ' . $elements{$length});
    }
}

