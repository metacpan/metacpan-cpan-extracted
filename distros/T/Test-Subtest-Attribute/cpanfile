on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'runtime' => sub {
    requires 'Attribute::Handlers';
    requires 'Test::Builder';
};

on 'test' => sub {
    requires 'English';
    requires 'Test::More', '0.99';
};

on 'develop' => sub {
    requires 'Archive::Tar::Wrapper', '0.15';
    requires 'Dist::Zilla::Plugin::ChangelogFromGit';
    requires 'Dist::Zilla::Plugin::CopyFilesFromBuild';
    requires 'Dist::Zilla::Plugin::GithubMeta';
    requires 'Dist::Zilla::Plugin::MetaProvides::Package';
    requires 'Dist::Zilla::Plugin::MetaTests';
    requires 'Dist::Zilla::Plugin::MinimumPerl';
    requires 'Dist::Zilla::Plugin::NextRelease';
    requires 'Dist::Zilla::Plugin::PodSyntaxTests';
    requires 'Dist::Zilla::Plugin::PodWeaver';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
    requires 'Dist::Zilla::Plugin::Test::Compile';
    requires 'Dist::Zilla::Plugin::Test::Kwalitee';
    requires 'Dist::Zilla::Plugin::Test::MinimumVersion';
    requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
    requires 'Dist::Zilla::Plugin::Test::Portability';
    requires 'Dist::Zilla::Plugin::Test::Version';
    requires 'Dist::Zilla::Plugin::VersionFromModule';
    requires 'Dist::Zilla::PluginBundle::Basic';
    requires 'Dist::Zilla::PluginBundle::Git';
    requires 'Pod::Coverage::TrustPod';
    requires 'Software::License::Perl_5';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod', '1.14';
    requires 'Test::TestCoverage';
};
