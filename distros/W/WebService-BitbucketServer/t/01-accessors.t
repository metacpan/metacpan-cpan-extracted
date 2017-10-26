#!perl

use warnings;
use strict;

use lib 't/lib';

use Test::More tests => 1;
use WebService::BitbucketServer;

my $api = WebService::BitbucketServer->new(
    base_url    => 'https://stash.example.com/',
    username    => 'bob',
    password    => 'secret',
);

my @api_accessors = qw(
    new

    base_url
    username
    password

    path
    url

    ua
    any_ua

    json

    no_security_warning

    call

    access_tokens
    core
    audit
    ref_restriction
    branch
    build
    comment_likes
    default_reviewers
    git
    gpg
    jira
    ssh
    mirroring_upstream
    repository_ref_sync
);
can_ok($api, @api_accessors);

