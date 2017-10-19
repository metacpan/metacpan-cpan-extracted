requires 'Benchmark'               => '0';
requires 'Carp'                    => '0';
requires 'English'                 => '0';
requires 'Error'                   => '0';
requires 'Test::Builder'           => '0';
requires 'Test::Builder::Module'   => '0';
requires 'perl'                    => '5.006';

on 'build' => sub {
    requires 'Module::Build'           => '0.30';
};

on 'test' => sub {
    requires 'File::Spec'              => '0';
    requires 'IO::Handle'              => '0';
    requires 'IPC::Open3'              => '0';
    requires 'Pod::Coverage::TrustPod' => '0';
    requires 'Test::Fatal'             => '0';
    requires 'Test::Kwalitee'          => '1.21';
    requires 'Test::More'              => '0';
    requires 'Test::Pod'               => '1.41';
    requires 'Test::Pod::Coverage'     => '1.08';
    requires 'Test::Tester'            => '0';
};

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker'     => '0';
    requires 'Module::Build'           => '0.30';
};

on 'develop' => sub {
    requires 'Pod::Coverage::TrustPod' => '0';
    requires 'Test::CPAN::Changes'     => '0.19';
    requires 'Test::CPAN::Meta::JSON'  => '0.16';
    requires 'Test::Kwalitee'          => '1.21';
    requires 'Test::Perl::Critic'      => '0';
    requires 'Test::Pod'               => '1.41';
    requires 'Test::Pod::Coverage'     => '1.08';
};
