on 'runtime' => sub {
    requires 'strict';
    requires 'warnings';
    requires 'Carp';
    requires 'Getopt::Long' => '2.4';  # the shorten app
    requires 'LWP::UserAgent' => '5.835';
    requires 'Try::Tiny' => '0.24';
};

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker' => '6.52';
};

on 'test' => sub {
    requires 'Test::More' => '0.88';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::PluginBundle::Starter' => 'v4.0.0';
    requires 'Dist::Zilla::Plugin::MinimumPerl';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::CPAN::Meta';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
