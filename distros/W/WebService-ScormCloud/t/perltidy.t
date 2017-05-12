#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More;

unless ($ENV{TEST_AUTHOR})
{
    plan skip_all =>
      'Set $ENV{TEST_AUTHOR} to a true value to run perltidy tests.';
}

eval { require Test::PerlTidy };
if ($@)
{
    plan skip_all => 'Test::PerlTidy required to run perltidy tests.';
}

eval { require Perl::Tidy };
if ($@)
{
    plan skip_all => 'Perl::Tidy required to run perltidy tests.';
}

my $perltidyrc = File::Spec->catfile('t', '_perltidyrc.txt');

Test::PerlTidy::run_tests(perltidyrc => $perltidyrc);

