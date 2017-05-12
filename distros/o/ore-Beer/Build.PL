use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ore::Beer',
    license             => 'perl',
    dist_author         => 'Jonathan "Duke" Leto <jonathan@leto.net>',
    dist_version_from   => 'lib/ore/Beer.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'ore::Beer-*' ],
    configure_requires => { 'Module::Build'  => 0.38 },
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/leto/ore-Beer/tree/master'
        },
    },
);

$builder->create_build_script();
print "More beer, please!\n";
