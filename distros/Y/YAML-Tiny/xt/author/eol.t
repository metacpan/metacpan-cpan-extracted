use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/YAML/Tiny.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_api.t',
    't/01_compile.t',
    't/10_read.t',
    't/11_read_string.t',
    't/12_write.t',
    't/13_write_string.t',
    't/20_subclass.t',
    't/21_yamlpm_compat.t',
    't/30_yaml_spec_tml.t',
    't/31_local_tml.t',
    't/32_world_tml.t',
    't/86_fail.t',
    't/lib/SubtestCompat.pm',
    't/lib/TestBridge.pm',
    't/lib/TestML/Tiny.pm',
    't/lib/TestUtils.pm',
    't/tml',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/compare/roundtrip.t',
    'xt/lib/ExtraTest.pm',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
