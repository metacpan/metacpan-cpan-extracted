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

    ['npm', '~1.2.3',            'vers:npm/>=1.2.3|<1.3.0'],
    ['npm', '^1.2.3',            'vers:npm/>=1.2.3|<2.0.0'],
    ['npm', '^0.2.3',            'vers:npm/>=0.2.3|<0.3.0'],
    ['npm', '~0.2.3',            'vers:npm/>=0.2.3|<0.3.0'],
    ['npm', '1.2.x',             'vers:npm/>=1.2.0|<1.3.0'],
    ['npm', '>=1.2.3 <2.0.0',    'vers:npm/>=1.2.3|<2.0.0'],
    ['npm', '1.2.3 - 2.3.4',     'vers:npm/>=1.2.3|<=2.3.4'],
    ['npm', '~1.6.5 || >=1.7.2', 'vers:npm/>=1.6.5|<1.7.0|>=1.7.2'],

    ['semver', '^1.2.3', 'vers:semver/>=1.2.3|<2.0.0'],

    ['gem', '~> 3.0',           'vers:gem/>=3.0|<4.0'],
    ['gem', '~> 3.0.0',         'vers:gem/>=3.0.0|<4.0'],
    ['gem', '~> 3',             'vers:gem/>=3|<4.0'],
    ['gem', '>= 3.0',           'vers:gem/>=3.0'],
    ['gem', '!= 1.5.1',         'vers:gem/!=1.5.1'],
    ['gem', '= 2.0.0',          'vers:gem/=2.0.0'],
    ['gem', ' ~>  3.5.0 ',      'vers:gem/>=3.5.0|<3.6'],
    ['gem', '>= 1.9, < 5.0',    'vers:gem/>=1.9|<5.0'],
    ['gem', '< 5.0, >= 1.9',    'vers:gem/<5.0|>=1.9'],
    ['gem', '~> 2.0, >= 2.0.3', 'vers:gem/>=2.0|<3.0|>=2.0.3'],

    ['nginx', '1.0.0-1.0.1', 'vers:nginx/>=1.0.0|<=1.0.1'],
    ['nginx', '1.0.1+',      'vers:nginx/>=1.0.1|<1.1.0'],

    ['conan', '>=1.0 <2.0', 'vers:conan/>=1.0|<2.0'],
    ['conan', '~1.2.3',     'vers:conan/>=1.2.3|<1.3-'],
    ['conan', '^1.2.3',     'vers:conan/>=1.2.3|<2-'],
    ['conan', '*',          'vers:conan/>=0.0.0'],
    ['conan', '1.2.3',      'vers:conan/1.2.3'],
);
#>>>

foreach my $test (@test_cases) {

    my ($scheme, $native_range, $expected) = @{$test};

    my $got   = native_range_to_vers($scheme, $native_range);
    my $label = "[$scheme] $native_range == $expected";

    is $got, $expected, $label or diag explain {got => $got, expected => $expected, scheme => $scheme};

}

done_testing();
