use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Time/Duration/Concise.pm',
    'lib/Time/Duration/Concise/Locale/ar.pm',
    'lib/Time/Duration/Concise/Locale/de.pm',
    'lib/Time/Duration/Concise/Locale/es.pm',
    'lib/Time/Duration/Concise/Locale/fr.pm',
    'lib/Time/Duration/Concise/Locale/hi.pm',
    'lib/Time/Duration/Concise/Locale/id.pm',
    'lib/Time/Duration/Concise/Locale/it.pm',
    'lib/Time/Duration/Concise/Locale/ja.pm',
    'lib/Time/Duration/Concise/Locale/ms.pm',
    'lib/Time/Duration/Concise/Locale/pl.pm',
    'lib/Time/Duration/Concise/Locale/pt.pm',
    'lib/Time/Duration/Concise/Locale/ru.pm',
    'lib/Time/Duration/Concise/Locale/vi.pm',
    'lib/Time/Duration/Concise/Locale/zh_cn.pm',
    'lib/Time/Duration/Concise/Locale/zh_tw.pm',
    'lib/Time/Duration/Concise/Localize.pm',
    'lib/Time/Duration/Concise/Localize.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-concise_test.t',
    't/02-concise_localize.t',
    't/03-concise_more.t',
    't/04-concise_as_string.t',
    't/04-concise_more.t',
    't/05-concise_as_concise.t',
    't/06-localize.t',
    't/boilerplate.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
