use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/YA/CLI.pm',
    'lib/YA/CLI/ActionRole.pm',
    'lib/YA/CLI/ErrorHandler.pm',
    'lib/YA/CLI/Usage.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/100-base.t',
    't/200-subsubcommand.t',
    't/lib/Test/YA/CLI/Example.pm',
    't/lib/Test/YA/CLI/Example/Main.pm',
    't/lib/Test/YA/CLI/Example/Something.pm',
    't/lib/Test/YA/CLI/Example/Something/Else.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
