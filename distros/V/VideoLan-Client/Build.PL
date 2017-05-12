use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'VideoLan::Client',
    license             => 'perl',
    dist_author         => 'Cyrille Hombecq <cyrille.hombecq@gmail.com>',
    dist_version_from   => 'lib/VideoLan/Client.pm',
    build_requires => {
        'Net::Telnet' => 0,
#        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'VideoLan-Client-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
