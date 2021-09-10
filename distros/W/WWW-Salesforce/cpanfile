on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'base';
    requires 'DateTime';
    requires 'Exporter' => '5.57';
    requires 'IO::Socket::SSL' => '1.94';
    requires 'LWP::Protocol::https' => '6.00';
    requires 'SOAP::Lite' => '1.0';
    requires 'URI';
};

on 'build' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'strict';
    requires 'warnings';
    requires 'DateTime';
    requires 'File::Spec';
    requires 'POSIX';
    requires 'SOAP::Lite';
    requires 'Test::More' => '0.88';
};

on 'develop' => sub {
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
