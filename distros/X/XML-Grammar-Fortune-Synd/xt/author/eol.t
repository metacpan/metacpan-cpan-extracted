use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/XML/Grammar/Fortune/Synd.pm',
    'lib/XML/Grammar/Fortune/Synd/App.pm',
    'lib/XML/Grammar/Fortune/Synd/Heap/Elem.pm',
    't/00-compile.t',
    't/00-load.t',
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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
