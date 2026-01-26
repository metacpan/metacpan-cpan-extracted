#!perl -T

use strict;
use warnings;

use Test::More;

use URI::VersionRange::Util qw(native_range_to_vers);

#<<<
my @test_cases = (
    ['nuget', '1.0',       'vers:nuget/1.0'],
    ['nuget', '[1.0,)',    'vers:nuget/>=1.0'],
    ['nuget', '(1.0,)',    'vers:nuget/>1.0'],
    ['nuget', '[1.0]',     'vers:nuget/1.0'],
    ['nuget', '(,1.0]',    'vers:nuget/>0.0|<=1.0'],
    ['nuget', '(,1.0)',    'vers:nuget/>0.0|<1.0'],
    ['nuget', '[1.0,2.0]', 'vers:nuget/>=1.0|<=2.0'],
    ['nuget', '(1.0,2.0)', 'vers:nuget/>1.0|<2.0'],
    ['nuget', '[1.0,2.0)', 'vers:nuget/>=1.0|<2.0'],

    ['raku', '*',       'vers:raku/*'],
    ['raku', '1.*',     'vers:raku/>=1'],
    ['raku', '1.0',     'vers:raku/1.0'],
    ['raku', '1.0.*',   'vers:raku/>=1.0'],
    ['raku', '1.0.*.5', 'vers:raku/>=1.0'],
    ['raku', '1.0+',    'vers:raku/>=1.0'],
);
#>>>

foreach my $test (@test_cases) {

    my ($scheme, $native_range, $expected) = @{$test};

    my $got   = native_range_to_vers($scheme, $native_range);
    my $label = "[$scheme] $native_range == $expected";

    is $got, $expected, $label or diag explain {got => $got, expected => $expected, scheme => $scheme};

}

done_testing();
