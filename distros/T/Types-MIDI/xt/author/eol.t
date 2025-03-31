use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Types/MIDI.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/lib/TestPercussion.pm',
    't/library_functions.t',
    't/midi-perl_percussion.t',
    't/test_percussion.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
