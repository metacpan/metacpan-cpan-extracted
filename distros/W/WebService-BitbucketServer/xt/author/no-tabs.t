use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/BitbucketServer.pm',
    'lib/WebService/BitbucketServer/AccessTokens/V1.pm',
    'lib/WebService/BitbucketServer/Audit/V1.pm',
    'lib/WebService/BitbucketServer/Branch/V1.pm',
    'lib/WebService/BitbucketServer/Build/V1.pm',
    'lib/WebService/BitbucketServer/CommentLikes/V1.pm',
    'lib/WebService/BitbucketServer/Core/V1.pm',
    'lib/WebService/BitbucketServer/DefaultReviewers/V1.pm',
    'lib/WebService/BitbucketServer/GPG/V1.pm',
    'lib/WebService/BitbucketServer/Git/V1.pm',
    'lib/WebService/BitbucketServer/JIRA/V1.pm',
    'lib/WebService/BitbucketServer/MirroringUpstream/V1.pm',
    'lib/WebService/BitbucketServer/RefRestriction/V2.pm',
    'lib/WebService/BitbucketServer/RepositoryRefSync/V1.pm',
    'lib/WebService/BitbucketServer/Response.pm',
    'lib/WebService/BitbucketServer/SSH/V1.pm',
    'lib/WebService/BitbucketServer/Spec.pm',
    'lib/WebService/BitbucketServer/WADL.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-accessors.t',
    't/10-request.t',
    't/20-response.t',
    't/21-paged-response.t',
    't/lib/MockBackend.pm',
    'xt/author/clean-namespaces.t',
    'xt/author/critic.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
