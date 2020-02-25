use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WWW/Mechanize/Cached.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/002-bad-custom-cache.t',
    't/003-basic.t',
    't/004-cached.t',
    't/005-custom-cache.t',
    't/006-cached-chi.t',
    't/007-clear-cache.t',
    't/007-initialize-warnings.t',
    't/TestCache.pm',
    't/cache_key.t',
    't/cache_ok.t',
    't/default.t',
    't/is_cached.t',
    't/pages/1.html',
    't/pages/10.html',
    't/pages/2.html',
    't/pages/3.html',
    't/pages/4.html',
    't/pages/5.html',
    't/pages/6.html',
    't/pages/7.html',
    't/pages/8.html',
    't/pages/9.html'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
