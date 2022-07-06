use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/YAFT.pm',
    'lib/Test/YAFT/Arrange.pm',
    'lib/Test/YAFT/Attributes.pm',
    'lib/Test/YAFT/Cmp.pm',
    'lib/Test/YAFT/Cmp/Compare.pm',
    'lib/Test/YAFT/Cmp/Complement.pm',
    'lib/Test/YAFT/Got.pm',
    'lib/Test/YAFT/Introduction.pod',
    'lib/Test/YAFT/Test/Deep.pod',
    'lib/Test/YAFT/Test/Exception.pod',
    'lib/Test/YAFT/Test/More.pod',
    'lib/Test/YAFT/Test/Spec.pod',
    'lib/Test/YAFT/Test/Warnings.pod',
    't/act.t',
    't/arrange.t',
    't/examples/test-rest-countries/resource-countries.t',
    't/examples/test-rest-countries/test-helper.pl',
    't/examples/test-type-tiny-constraint/constraint-test.t',
    't/examples/test-type-tiny-constraint/test-helper.pl',
    't/expect-compare.t',
    't/expect-complement.t',
    't/expect-value.t',
    't/fail.t',
    't/internals-build-got.t',
    't/it-with-got.t',
    't/it.t',
    't/nok.t',
    't/ok.t',
    't/subtest.t',
    't/test-frame.t',
    't/test-helper.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
