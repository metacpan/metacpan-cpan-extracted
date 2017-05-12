use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::Array::Boolean',
    license             => 'perl',
    dist_author         => 'Kyle Hasselbacher <kyleha@gmail.com>',
    dist_version_from   => 'lib/Tie/Array/Boolean.pm',
    requires => {
        'Test::More' => 0,
        'Tie::Array' => 0,
    },
    add_to_cleanup      => [ 'Tie-Array-Boolean-*' ],
);

$builder->create_build_script();
