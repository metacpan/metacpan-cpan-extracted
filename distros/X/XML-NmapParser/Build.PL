use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::NmapParser',
    license             => 'artistic_2',
    dist_author         => q{P Johnson [littleurl] <pjohnson21211@gmail.com>},
    dist_version_from   => 'lib/XML/NmapParser.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'XML-NmapParser-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
