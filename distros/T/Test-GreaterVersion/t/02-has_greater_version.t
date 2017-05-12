#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

my $module='Test::GreaterVersion';

use_ok($module) or exit;
can_ok($module, 'has_greater_version');

# look in the test directory
no warnings 'once';
$Test::GreaterVersion::libdir = 't/lib';
use warnings 'once';

# no module name
{
    my $expected=0;
    my $got=has_greater_version();
    is($got, $expected,'no module name');
}

# name of module that's not installed,
# lib has version
{
    my $expected=1;
    my $got=has_greater_version("A::Version");
    is($got, $expected, 'lib has version, not installed');
}

# name of module that's not installed,
# lib doesn't have version
{
    my $expected=0;
    my $got=has_greater_version("A::NoVersion");
    is($got, $expected, 'lib doesn\'t have version, not installed');
}

# name of module not in lib, not installed
{
    my $expected=0;
    my $got=has_greater_version('A::IDontExist');
    is($got, $expected, 'of module not in lib, not installed');
}

# name of module not in lib, installed
{
    my $expected=0;
    my $got=has_greater_version('ExtUtils::MakeMaker');
    is($got, $expected, 'name of module not in lib, installed');
}
=head2 AUTOR

Gregor Goldbach <glauschwuffel@nomaden.org>

