use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Win32::Mock',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Win32/Mock.pm',
    requires => {
        'constant'          => '1.12',
        'Devel::FakeOSName' => 0,
        'ExtUtils::Command' => 0,
        'File::Basename'    => 0,
        'File::Spec'        => '0.7',
    },
    recommends => {
        'Data::GUID'        => 0,
        'File::HomeDir'     => 0,
    }, 
    build_requires => {
        'Test::More'        => 0,
    },
    test_files          => [qw(t/*.t  t/*/*.t  t/*/*/*.t)],
    add_to_cleanup      => [ 'Win32-Mock-*' ],
);

$builder->create_build_script();
