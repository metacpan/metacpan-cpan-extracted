# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'perl' => '5.012';

requires 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'JSON';
requires 'Moo';
requires 'PerlX::Maybe';
requires 'Types::Standard';

recommends 'Text::CSV';

on test => sub {
    requires 'Test2::V0';

    requires 'Archive::Extract';
    requires 'LWP::UserAgent::Mockable';
    requires 'Time::Piece';

    suggests 'Archive::Zip';
};

on 'develop' => sub {
  requires 'perl' => '5.026'; # postfix deref, hash slices, Test2, indented here-docs

  requires 'Dist::Zilla';

  recommends 'Data::Dumper::Concise';
  recommends 'Dist::Zilla::PluginBundle::Git';
  recommends 'Dist::Zilla::Plugin::GithubMeta';
  recommends 'Dist::Zilla::Plugin::NextRelease';

  # these were missing when I tried to dzil test
  recommends 'Dist::Zilla::Plugin::MetaProvides::Package';
  recommends 'Dist::Zilla::Plugin::RPM';
  recommends 'Dist::Zilla::Plugin::Repository';
};
