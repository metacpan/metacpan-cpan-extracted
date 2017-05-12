use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Wedata',
    license             => 'perl',
    dist_author         => 'Tsutomu KOYACHI <rtk2106@gmail.com>',
    dist_version_from   => 'lib/WebService/Wedata.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'LWP::UserAgent' => 0,
        'JSON::XS'   => 0,
    },
    add_to_cleanup      => [ 'WebService-Wedata-*' ],
);

$builder->create_build_script();
