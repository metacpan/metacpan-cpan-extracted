use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Synopsis.pm',
    't/00-compile.t',
    't/01-fail-if-SYNOPSIS-has-errors.t',
    't/02-END-token-errors.t',
    't/03-end-in-pod.t',
    't/04-HEREDOC.t',
    't/05-multi-chunks-clash.t',
    't/05-multi-files-clash.t',
    't/06-for.t',
    't/07-nopod.t',
    't/08-plain-text-in-pod.t',
    't/09-synopsis.t',
    't/10-in-pod-skip.t',
    't/11-DATA-in-pod.t',
    't/12-DATA-token-errors.t',
    't/lib/BrokenSYNOPSIS01.pm',
    't/lib/ENDInPod.pm',
    't/lib/ENDInPodWithError.pm',
    't/lib/NoPod.pm',
    't/lib/PlainTextInPod.pm',
    't/lib/Test03.pm',
    't/lib/Test03Other.pm',
    't/lib/Test04HEREDOC.pm',
    't/lib/Test10HEREDOC.pm',
    't/lib/Test10InPodSkipWithBegin.pm',
    't/lib/Test11DATAInPod.pm',
    't/lib/Test12DATAInPodWithError.pm',
    't/lib/TestMultipleChunks.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
