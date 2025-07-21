# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'perl' => '5.008';

requires 'HTTP::Tiny';
requires 'IO::Socket::SSL';
requires 'JSON';
requires 'Moo';
requires 'PerlX::Maybe';
requires 'Types::Standard';

recommends 'Text::CSV';
recommends 'URI';

on test => sub {
    requires 'Test2::V0';

    requires 'Time::Piece';

    recommends 'Archive::Extract';
    recommends 'LWP::UserAgent';
    recommends 'LWP::UserAgent::Mockable'; # stronly recommended

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
