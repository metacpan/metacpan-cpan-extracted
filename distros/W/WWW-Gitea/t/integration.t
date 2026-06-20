#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);
use WWW::Gitea;

# Live integration test against a real Gitea instance. Network + write access.
# Runs ONLY when both env vars are set (TEST_-prefixed per house rules, so a
# plain `prove` / `dzil test` never touches a real server):
#
#   TEST_GITEA_URL=http://localhost:3000 \
#   TEST_GITEA_TOKEN=<token> prove -lv t/integration.t
#
# It creates a throwaway repo + org and deletes them again on the way out.

my $url   = $ENV{TEST_GITEA_URL};
my $token = $ENV{TEST_GITEA_TOKEN};
plan skip_all => 'set TEST_GITEA_URL and TEST_GITEA_TOKEN for live tests'
    unless $url && $token;

my $gitea = WWW::Gitea->new(url => $url, token => $token);

# Unique-ish names for this run (the server is a throwaway, so fixed is fine).
my $REPO = 'wwwgitea-itest';
my $ORG  = 'wwwgitea-itest-org';

my $me = $gitea->current_user;
my $owner = $me->login;
ok $owner, "current_user -> $owner";
like $gitea->version, qr/^\d+\./, 'version looks like a version';

# Clean up anything left over from a previous run, then guarantee teardown.
_destroy();
END { _destroy() if $gitea }

# --- repository -----------------------------------------------------------

my $repo = $gitea->repos->create(
    name => $REPO, description => 'live test', private => \1, auto_init => \1);
isa_ok $repo, 'WWW::Gitea::Repo', 'repos->create';
is $repo->name, $REPO, 'created repo name';
is $repo->owner_login, $owner, 'created repo owner';
my $branch = $repo->default_branch || 'main';

my $got = $gitea->repos->get($owner, $REPO);
is $got->full_name, "$owner/$REPO", 'repos->get round-trip';

$gitea->repos->edit($owner, $REPO, description => 'edited');
is $gitea->repos->get($owner, $REPO)->description, 'edited', 'repos->edit';

ok scalar(@{ $gitea->repos->list(limit => 50) }), 'repos->list returns repos';

# --- labels ---------------------------------------------------------------

my $label = $gitea->labels->create($owner, $REPO,
    name => 'bug', color => 'ee0701', description => 'broke');
isa_ok $label, 'WWW::Gitea::Label', 'labels->create';
is $label->name, 'bug', 'label name';
$label->edit(color => '00ff00');
is $gitea->labels->get($owner, $REPO, $label->id)->color, '00ff00', 'labels->edit';
ok scalar(@{ $gitea->labels->list($owner, $REPO) }), 'labels->list';

# --- milestones -----------------------------------------------------------

my $ms = $gitea->milestones->create($owner, $REPO, title => 'v1', description => 'first');
isa_ok $ms, 'WWW::Gitea::Milestone', 'milestones->create';
is $ms->title, 'v1', 'milestone title';
$ms->close;
is $gitea->milestones->get($owner, $REPO, $ms->id)->state, 'closed', 'milestone->close';

# --- issues + comments ----------------------------------------------------

my $issue = $gitea->issues->create($owner, $REPO,
    title => 'something broke', body => 'details',
    labels => [ $label->id ]);
isa_ok $issue, 'WWW::Gitea::Issue', 'issues->create';
ok $issue->number, 'issue has a number';
is_deeply $issue->label_names, ['bug'], 'issue carries the label';

my $comment = $issue->add_comment('looking into it');
isa_ok $comment, 'WWW::Gitea::Comment', 'issue->add_comment';
is $comment->body, 'looking into it', 'comment body';
ok scalar(@{ $gitea->issues->comments($owner, $REPO, $issue->number) }), 'issues->comments';

$issue->close;
is $gitea->issues->get($owner, $REPO, $issue->number)->state, 'closed', 'issue->close';
ok scalar(@{ $gitea->issues->list($owner, $REPO, state => 'closed') }), 'issues->list closed';
# cross-repo search by keyword (q) goes through Gitea's async issue indexer, so
# don't depend on it here; state=all without q is DB-backed and deterministic.
ok scalar(@{ $gitea->issues->search(state => 'all', type => 'issues') }),
    'issues->search (cross-repo, DB-backed)';

# --- pull request (create a branch+file via the low-level request, then PR) -

$gitea->request('POST', "/repos/$owner/$REPO/contents/feature.txt", body => {
    content    => encode_base64('hello from a feature branch', ''),
    message    => 'add feature.txt',
    branch     => $branch,
    new_branch => 'feature',
});

my $pr = $gitea->pulls->create($owner, $REPO,
    head => 'feature', base => $branch, title => 'add feature');
isa_ok $pr, 'WWW::Gitea::PullRequest', 'pulls->create';
ok $pr->number, 'pr has a number';
is $pr->base_branch, $branch, 'pr base branch';
is $gitea->pulls->is_merged($owner, $REPO, $pr->number), 0, 'is_merged false before merge';

# Gitea computes PR mergeability asynchronously — wait for it before merging,
# otherwise the merge call races and Gitea rejects it.
my $mergeable;
for (1 .. 30) {
    $mergeable = $gitea->pulls->get($owner, $REPO, $pr->number)->mergeable;
    last if $mergeable;
    select undef, undef, undef, 0.5;
}
ok $mergeable, 'pr became mergeable';
$gitea->pulls->merge($owner, $REPO, $pr->number, Do => 'squash');
is $gitea->pulls->is_merged($owner, $REPO, $pr->number), 1, 'is_merged true after merge';

# --- releases -------------------------------------------------------------

my $rel = $gitea->releases->create($owner, $REPO,
    tag_name => 'v1.0.0', name => 'First', body => 'notes', target_commitish => $branch);
isa_ok $rel, 'WWW::Gitea::Release', 'releases->create';
is $rel->tag_name, 'v1.0.0', 'release tag';
is $gitea->releases->get_by_tag($owner, $REPO, 'v1.0.0')->id, $rel->id, 'releases->get_by_tag';
ok scalar(@{ $gitea->releases->list($owner, $REPO) }), 'releases->list';

# --- organizations --------------------------------------------------------

my $org = $gitea->orgs->create(username => $ORG, full_name => 'Test Org');
isa_ok $org, 'WWW::Gitea::Org', 'orgs->create';
is $org->name, $ORG, 'org name';
is $gitea->orgs->get($ORG)->name, $ORG, 'orgs->get';

my $org_repo = $gitea->repos->create(org => $ORG, name => 'orgrepo', auto_init => \1);
is $org_repo->owner_login, $ORG, 'repos->create in org';
ok scalar(@{ $gitea->orgs->repos($ORG) }), 'orgs->repos';

done_testing;

sub _destroy {
    eval { $gitea->repos->delete($owner, $REPO) };
    eval { $gitea->repos->delete($ORG, 'orgrepo') };
    eval { $gitea->orgs->delete($ORG) };
    return;
}
