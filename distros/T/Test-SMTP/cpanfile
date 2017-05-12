requires 'perl', '5.8.5';
requires 'IO::Socket::SSL', '1.01';
requires 'Net::SMTP_auth';
requires 'Test::Builder::Module';
requires 'Test::Builder::Tester', '1.02';

on test => sub {
  requires 'Net::Server::Mail', '0.13';
  requires 'Net::Server::Mail::ESMTP::AUTH';
  requires 'Test::Exception', '0.21';
  requires 'Test::More', '0.62';
  requires 'Test::Pod';
  requires 'Test::Pod::Coverage';
  requires 'Test::Simple', '0.44';
};

on develop => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::ChangelogFromGit';
  requires 'Dist::Zilla::Plugin::Git::NextVersion';
  requires 'Dist::Zilla::Plugin::OurPkgVersion';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
  requires 'Dist::Zilla::PluginBundle::Git';
};
