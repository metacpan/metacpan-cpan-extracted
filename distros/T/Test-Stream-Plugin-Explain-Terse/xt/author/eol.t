use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Stream/Plugin/Explain/Terse.pm',
    't/00-compile/lib_Test_Stream_Plugin_Explain_Terse_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/bundle_import.t',
    't/hash_multiline.t',
    't/lib/T/Grapheme.pm',
    't/stream_import.t',
    't/string_long.t',
    't/string_newline.t',
    't/string_short.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
