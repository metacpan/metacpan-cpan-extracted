#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);
use HTTP::Request;
use WWW::Gitea;
use WWW::Gitea::Repo;
use WWW::Gitea::Issue;
use WWW::Gitea::PullRequest;

# --- api_url derivation ---------------------------------------------------

is( WWW::Gitea->new(url => 'https://gitea.example.com')->api_url,
    'https://gitea.example.com/api/v1', 'api_url from plain url' );

is( WWW::Gitea->new(url => 'https://gitea.example.com/')->api_url,
    'https://gitea.example.com/api/v1', 'trailing slash stripped' );

is( WWW::Gitea->new(url => 'https://gitea.example.com/api/v1')->api_url,
    'https://gitea.example.com/api/v1', 'accidental /api/v1 suffix tolerated' );

eval { WWW::Gitea->new->api_url };
like( $@, qr/url required/, 'missing url dies' );

my $gitea = WWW::Gitea->new(
    url   => 'https://gitea.example.com',
    token => 'SECRET',
);

# --- operation tables -----------------------------------------------------

is( $gitea->repos->get_operation('repos.get')->{path},
    '/repos/{owner}/{repo}', 'repos.get path' );

is( $gitea->repos->get_operation('repos.create_current')->{method},
    'POST', 'create in current user namespace is POST /user/repos' );
is( $gitea->repos->get_operation('repos.create_current')->{path},
    '/user/repos', 'repos.create_current path' );

is( $gitea->issues->get_operation('issues.search')->{path},
    '/repos/issues/search', 'cross-repo issue search lives under /repos' );

is( $gitea->pulls->get_operation('pulls.is_merged')->{method},
    'GET', 'is_merged shares the merge path via GET' );
is( $gitea->pulls->get_operation('pulls.merge')->{method},
    'POST', 'merge is POST on the same path' );

is( $gitea->releases->get_operation('releases.get_by_tag')->{path},
    '/repos/{owner}/{repo}/releases/tags/{tag}', 'release-by-tag path' );

is( $gitea->labels->get_operation('labels.get')->{path},
    '/repos/{owner}/{repo}/labels/{id}', 'labels addressed by {id}' );

is( $gitea->orgs->get_operation('orgs.list_current')->{path},
    '/user/orgs', 'current user orgs path' );

# --- path parameter substitution -----------------------------------------

my $issues = $gitea->issues;
is( $issues->_resolve_path('/repos/{owner}/{repo}/issues/{index}',
        { owner => 'getty', repo => 'p5-www-gitea', index => 7 }),
    '/repos/getty/p5-www-gitea/issues/7', 'path param substitution' );

eval { $issues->_resolve_path('/a/{missing}', {}) };
like( $@, qr/missing path parameter/, 'missing path param dies' );

eval { $issues->get_operation('does.not.exist') };
like( $@, qr/unknown operationId/, 'unknown op dies' );

# --- authentication header ------------------------------------------------

{
    my $req = HTTP::Request->new(GET => 'https://x/');
    $gitea->_apply_auth($req);
    is( $req->header('Authorization'), 'token SECRET', 'token auth header' );
}

{
    my $basic = WWW::Gitea->new(
        url => 'https://x', username => 'bob', password => 'pw');
    my $req = HTTP::Request->new(GET => 'https://x/');
    $basic->_apply_auth($req);
    is( $req->header('Authorization'),
        'Basic ' . encode_base64('bob:pw', ''),
        'basic auth header when no token' );
}

# --- entity parsing: Repo -------------------------------------------------

my $repo = WWW::Gitea::Repo->new(client => $gitea, data => {
    id          => 42,
    name        => 'p5-www-gitea',
    full_name   => 'getty/p5-www-gitea',
    owner       => { login => 'getty' },
    private     => 0,
    fork        => 0,
    clone_url   => 'https://gitea.example.com/getty/p5-www-gitea.git',
    ssh_url     => 'git@gitea.example.com:getty/p5-www-gitea.git',
    default_branch    => 'main',
    stars_count       => 3,
    open_issues_count => 1,
});

is( $repo->name,        'p5-www-gitea',       'repo name' );
is( $repo->full_name,   'getty/p5-www-gitea', 'repo full_name' );
is( $repo->owner_login, 'getty',              'repo owner_login' );
is( $repo->default_branch, 'main',            'repo default_branch' );
is( $repo->stars_count, 3,                    'repo stars_count' );

# --- entity parsing: Issue (with embedded repository fallback) ------------

my $issue = WWW::Gitea::Issue->new(client => $gitea, data => {
    id     => 1001,
    number => 7,
    title  => 'Something broke',
    state  => 'open',
    user   => { login => 'reporter' },
    comments => 2,
    labels => [ { name => 'bug' }, { name => 'urgent' } ],
    assignees => [ { login => 'getty' } ],
    repository => { owner => 'getty', name => 'p5-www-gitea' },
});

is( $issue->number,     7,            'issue number' );
is( $issue->state,      'open',       'issue state' );
is( $issue->user_login, 'reporter',   'issue author login' );
is( $issue->comments_count, 2,        'issue comments count' );
is_deeply( $issue->label_names, ['bug', 'urgent'], 'issue label names' );
is_deeply( $issue->assignee_logins, ['getty'],     'issue assignee logins' );
is( $issue->_owner, 'getty',          'issue owner falls back to embedded repository' );
is( $issue->_repo,  'p5-www-gitea',   'issue repo falls back to embedded repository' );

# explicit owner/repo wins over embedded
my $issue2 = WWW::Gitea::Issue->new(client => $gitea, owner => 'x', repo => 'y',
    data => { number => 1, repository => { owner => 'getty', name => 'p5' } });
is( $issue2->_owner, 'x', 'explicit owner wins' );
is( $issue2->_repo,  'y', 'explicit repo wins' );

# --- entity parsing: PullRequest (base.repo fallback) ---------------------

my $pr = WWW::Gitea::PullRequest->new(client => $gitea, data => {
    id     => 2002,
    number => 12,
    title  => 'Add feature',
    state  => 'open',
    merged => 0,
    head   => { ref => 'feature' },
    base   => {
        ref  => 'main',
        repo => { name => 'p5-www-gitea', owner => { login => 'getty' } },
    },
});

is( $pr->number,      12,        'pr number' );
is( $pr->head_branch, 'feature', 'pr head branch' );
is( $pr->base_branch, 'main',    'pr base branch' );
is( $pr->_owner, 'getty',        'pr owner falls back to base.repo.owner.login' );
is( $pr->_repo,  'p5-www-gitea', 'pr repo falls back to base.repo.name' );

done_testing;
