use strict;
use warnings;

use Test::More;

my $min_tpc = 1.27;
eval "use Time::Seconds $min_tpc";
plan skip_all => "Time::Seconds $min_tpc required for testing" if $@;
plan tests => 15;

eval "use Test::NoWarnings";
use Time::Duration::Concise;

my @testcases = ({
        interval => '1h20m',
        score    => '1h20m'
    },
    {
        interval => '1d-20h',
        score    => '4h'
    },
    {
        interval => '1d-28h',
        score    => '-4h'
    },
    {
        interval => '1d28h',
        score    => '2d4h'
    },
    {
        interval => '2m-180s',
        score    => '-1m'
    },
    {
        interval => '1h-60m',
        score    => '0s'
    },
    {
        interval => '2h-60m',
        score    => '1h'
    });

foreach my $case (@testcases) {
    my $interval = $case->{'interval'};
    my $score    = $case->{'score'};
    my $object   = Time::Duration::Concise->new(interval => $interval);
    isa_ok(ref($object), 'Time::Duration::Concise', "Object creation for $interval");
    is($object->as_concise_string, $score, "$score matches.");
}
