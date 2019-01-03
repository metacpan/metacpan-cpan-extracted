#!perl

requires 'perl', '5.8.5';

requires 'IO::Socket::INET';
requires 'Moose';
requires 'Net::Server::Mail::ESMTP';
requires 'Test::Exception';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Pod';
  requires 'Test::SMTP';
};

on 'develop' => sub {
  requires 'ExtUtils::MakeMaker';
  requires 'Dist::Zilla::Plugin::MetaProvides::Package';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::ChangelogFromGit';
  requires 'Dist::Zilla::Plugin::Git::NextVersion';
  requires 'Dist::Zilla::Plugin::MetaJSON';
  requires 'Dist::Zilla::Plugin::MetaResources';
  requires 'Dist::Zilla::Plugin::OurPkgVersion';
  requires 'Dist::Zilla::Plugin::PodSyntaxTests';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::Prereqs';
  requires 'Dist::Zilla::Plugin::PruneFiles';
  requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
  requires 'Dist::Zilla::PluginBundle::Basic';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Dist::Zilla::Plugin::ReadmeAnyFromPod';
  requires 'Dist::Zilla::Plugin::ReadmeFromPod';
};

