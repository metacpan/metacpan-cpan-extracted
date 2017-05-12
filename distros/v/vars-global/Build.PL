use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'vars::global',
    license             => 'perl',
    dist_author         => 'Flavio Poletti <flavio [at] polettix [dot] it>',
    dist_version_from   => 'lib/vars/global.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'vars-global-*' ],
);

$builder->create_build_script();
