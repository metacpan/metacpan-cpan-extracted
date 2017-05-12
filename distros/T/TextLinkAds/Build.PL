use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [ 'TextLinkAds-*', ],
    build_requires     => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/TextLinkAds.pm',
    license            => 'perl',
    module_name        => 'TextLinkAds',
    requires           => {
        'Carp'             => 0,
        'File::Spec'       => 0,
        'LWP::UserAgent'   => 0,
        'XML::Simple'      => 0,
    },
    recommends         => {
        'Cache::FileCache' => 0,
    },
);

$builder->create_build_script();
