#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

my $module='Test::GreaterVersion';

use_ok($module) or exit;
can_ok($module, 'has_greater_version_than_cpan');

# look in the test directory
no warnings 'once';
$Test::GreaterVersion::libdir = 't/lib';
use warnings 'once';

# no module name
{
    my $expected=0;
    my $got=has_greater_version_than_cpan();
    is($got, $expected,'no module name');
}

# name of module that's not on CPAN,
# lib has version
{
    my $expected=1;
    my $got=has_greater_version_than_cpan("A::Version");
    is($got, $expected, 'lib has version, not on CPAN');
}

# name of module that's not on CPAN,
# lib doesn't have version
{
    my $expected=0;
    my $got=has_greater_version_than_cpan("A::NoVersion");
    is($got, $expected, 'lib doesn\'t have version, not on CPAN');
}

# name of module not in lib, not on CPAN
{
    my $expected=0;
    my $got=has_greater_version_than_cpan('A::IDontExist');
    is($got, $expected, 'of module not in lib, not on CPAN');
}

# name of module not in lib, on CPAN
{
    my $expected=0;
    my $got=has_greater_version_than_cpan('ExtUtils::MakeMaker');
    is($got, $expected, 'name of module not in lib, on CPAN');
}
=head2 AUTOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=cut