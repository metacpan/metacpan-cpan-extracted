use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Vtiger',
    license             => 'perl',
    dist_author         => q{Monsenhor <monsenhor@cpan.com>},
    dist_version_from   => 'lib/WebService/Vtiger.pm',
    build_requires => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'JSON'           => 0,
        'Digest::MD5'    => 0
    },
    add_to_cleanup      => [ 'WebService-Vtiger-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
