use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/lib/byversion.pm',
    't/00-compile/lib_lib_byversion_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_basic.t',
    't/02_import_ok.t',
    't/03_unimport.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
