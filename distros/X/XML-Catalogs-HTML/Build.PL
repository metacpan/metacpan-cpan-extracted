use strict;
use warnings;

use Module::Build 0.36;

my $build = Module::Build->new(
    module_name => 'XML::Catalogs::HTML',
    license     => 'open_source',  # Mix of CC0_1_0 and W3C Document License
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'XML::Catalogs' => 0,
        'version'       => 0,
    },
    share_dir => {
        module => {
            'XML::Catalogs::HTML' => [ 'share/html' ],
        },
    },
    add_to_cleanup => [ 'XML-Catalogs-HTML-*' ],
);

$build->create_build_script();
