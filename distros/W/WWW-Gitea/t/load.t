#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::Gitea
  WWW::Gitea::Role::HTTP
  WWW::Gitea::Role::OpenAPI
  WWW::Gitea::API::Misc
  WWW::Gitea::API::Users
  WWW::Gitea::API::Repos
  WWW::Gitea::API::Issues
  WWW::Gitea::API::PullRequests
  WWW::Gitea::API::Labels
  WWW::Gitea::API::Milestones
  WWW::Gitea::API::Releases
  WWW::Gitea::API::Orgs
  WWW::Gitea::User
  WWW::Gitea::Repo
  WWW::Gitea::Issue
  WWW::Gitea::PullRequest
  WWW::Gitea::Label
  WWW::Gitea::Milestone
  WWW::Gitea::Release
  WWW::Gitea::Org
  WWW::Gitea::Comment
  WWW::Gitea::Attachment
)) {
    use_ok($_);
}

done_testing;
