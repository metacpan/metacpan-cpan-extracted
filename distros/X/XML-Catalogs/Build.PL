use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'XML::Catalogs',
    license     => 'CC0_1_0',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'           => 0,
        'File::ShareDir' => 0,
        'URI::file'      => 0,
        'version'        => 0,
    },
    add_to_cleanup => [ 'XML-Catalogs-*' ],
);

$build->create_build_script();
