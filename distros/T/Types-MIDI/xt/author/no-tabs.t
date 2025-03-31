use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Types/MIDI.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/lib/TestPercussion.pm',
    't/library_functions.t',
    't/midi-perl_percussion.t',
    't/test_percussion.t'
);

notabs_ok($_) foreach @files;
done_testing;
