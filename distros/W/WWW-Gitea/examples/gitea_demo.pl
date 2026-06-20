#!/usr/bin/env perl
use strict;
use warnings;
use WWW::Gitea;

# A tiny end-to-end demo. Set the env vars first:
#
#   export GITEA_URL=https://gitea.example.com
#   export GITEA_TOKEN=...                     # Settings -> Applications -> Generate Token
#   perl examples/gitea_demo.pl getty p5-www-gitea
#
# It prints who you are and the Gitea version, then shows the given repo and
# its open issues. With no repo arguments it just lists your own repositories.

my ($owner, $repo) = @ARGV;

my $gitea = WWW::Gitea->new;   # url + token come from GITEA_URL / GITEA_TOKEN

my $me = $gitea->current_user;
printf "Authenticated as %s (Gitea %s)\n\n", $me->login, $gitea->version;

if ($owner && $repo) {
    my $r = $gitea->repos->get($owner, $repo);
    printf "%s  ★%d  ⑂%d\n  %s\n\n",
        $r->full_name, $r->stars_count // 0, $r->forks_count // 0,
        $r->description // '(no description)';

    my $issues = $r->issues(state => 'open', limit => 10);
    printf "Open issues (%d shown):\n", scalar @$issues;
    printf "  #%-4d %s  [%s]\n", $_->number, $_->title,
        join(',', @{ $_->label_names }) for @$issues;
}
else {
    my $repos = $gitea->repos->list(limit => 20);
    printf "Your repositories (%d shown):\n", scalar @$repos;
    printf "  %-40s ★%d\n", $_->full_name, $_->stars_count // 0 for @$repos;
}
