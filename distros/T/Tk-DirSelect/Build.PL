use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tk::DirSelect',
    license             => 'perl',
    dist_author         => 'Michael Carman <mjcarman@cpan.org>',
    dist_version_from   => 'lib/Tk/DirSelect.pm',
    requires            => {
        'Tk' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Tk-DirSelect-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
