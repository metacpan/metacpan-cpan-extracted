use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'WWW::KlickTel::API',
    license            => 'Artistic_2_0',
    dist_author        => q{Juergen Heine ( sysdef Æt cpan D0T org )},
    dist_version_from  => 'lib/WWW/KlickTel/API.pm',
    release_status     => 'unstable',
    configure_requires => { 'Module::Build' => 0, },
    create_readme      => 1,
    create_packlist    => 1,
    build_requires     => { 'Test::More' => 0, },
    requires           => {
        'perl'         => '5.010001', # perl 5.10.1
        'REST::Client' => 240,
        'JSON::XS'     => 2.32,
        'DB_File'      => 1.820,
    },
    add_to_cleanup     => ['WWW-KlickTel-API-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
