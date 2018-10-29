on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'Exporter';
    requires 'XSLoader';
};

on 'build' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'configure' => sub {
    requires 'Win32';
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'File::Spec';
    requires 'Test::More' => '0.88';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::CPAN::Meta';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
