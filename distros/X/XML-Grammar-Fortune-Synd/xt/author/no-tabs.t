use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/Grammar/Fortune/Synd.pm',
    'lib/XML/Grammar/Fortune/Synd/App.pm',
    'lib/XML/Grammar/Fortune/Synd/Heap/Elem.pm',
    't/00-compile.t',
    't/01-run.t',
    't/02-eliminate-old-ids.t',
    't/boilerplate.t',
    't/data/fortune-synd-1/irc-conversation-4-several-convos.xml',
    't/data/fortune-synd-1/screenplay-fort-sample-1.xml',
    't/data/fortune-synd-eliminate-old-ids-1/fort.yaml',
    't/data/fortune-synd-eliminate-old-ids-1/irc-conversation-4-several-convos.xml',
    't/data/fortune-synd-eliminate-old-ids-1/screenplay-fort-sample-1.xml',
    't/data/fortune-synd-many-fortunes/sharp-perl.xml',
    't/data/out-fortune-synd-1/PLACEHOLDER',
    't/data/out-fortune-synd-eliminate-old-ids-1/PLACEHOLDER',
    't/lib/SyndTempWrap.pm'
);

notabs_ok($_) foreach @files;
done_testing;
