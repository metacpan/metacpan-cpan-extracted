use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/perlfaq.pm',
    'lib/perlfaq.pod',
    'lib/perlfaq1.pod',
    'lib/perlfaq2.pod',
    'lib/perlfaq3.pod',
    'lib/perlfaq4.pod',
    'lib/perlfaq5.pod',
    'lib/perlfaq6.pod',
    'lib/perlfaq7.pod',
    'lib/perlfaq8.pod',
    'lib/perlfaq9.pod',
    'lib/perlglossary.pod'
);

notabs_ok($_) foreach @files;
done_testing;
