use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'examples/no_plan.t',
    'examples/sub.t',
    'examples/synopsis_1.t',
    'examples/synopsis_2.t',
    'examples/test_nowarnings.t',
    'examples/test_warning_contents.t',
    'examples/warning_like.t',
    'examples/with_done_testing.t',
    'examples/with_plan.t',
    'lib/Test/Warnings.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-done_testing.t',
    't/03-subtest.t',
    't/04-no-tests.t',
    't/05-no-end-block.t',
    't/06-skip-all.t',
    't/07-no_plan.t',
    't/08-use-if.t',
    't/09-warnings-contents.t',
    't/10-no-done_testing.t',
    't/11-double-use.t',
    't/12-no-newline.t',
    't/13-propagate-warnings.t',
    't/14-propagate-subname.t',
    't/15-propagate-default.t',
    't/16-propagate-ignore.t',
    't/17-propagate-subname-colons.t',
    't/18-propagate-subname-package.t',
    't/19-propagate-nonexistent-subname.t',
    't/20-propagate-stub.t',
    't/21-fail-on-warning.t',
    't/22-warnings-bareword.t',
    't/23-report-warnings.t',
    't/lib/SilenceStderr.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/examples_synopsis_1.t',
    'xt/author/examples_synopsis_2.t',
    'xt/author/examples_test_warning_contents.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
