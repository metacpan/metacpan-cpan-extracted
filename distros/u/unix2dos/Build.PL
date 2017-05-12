use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'unix2dos',
    license             => 'perl',
    dist_author         => q{Michael Fuersich <michael.fuersich@arcor.de>},
    dist_version_from   => 'lib/unix2dos.pm',
    dist_abstract       => "implements unix2dos and dos2unix in pure perl" ,
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'unix2dos-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
