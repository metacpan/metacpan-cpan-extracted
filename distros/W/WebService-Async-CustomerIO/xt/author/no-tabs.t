use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/Async/CustomerIO.pm',
    'lib/WebService/Async/CustomerIO.pod',
    'lib/WebService/Async/CustomerIO/Customer.pm',
    'lib/WebService/Async/CustomerIO/RateLimiter.pm',
    'lib/WebService/Async/CustomerIO/RateLimiter.pod',
    'lib/WebService/Async/CustomerIO/Trigger.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/api_client.t',
    't/customers.t',
    't/rate_limiter.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/trigger.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
