use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'YAGL',
    license           => 'artistic2',
    dist_author       => 'Rich Loveland <r@rmloveland.com>',
    dist_version_from => 'lib/YAGL.pm',
    requires          => {
        'Test::More'          => 0,
        'Text::CSV'           => 0,
        'Hash::PriorityQueue' => 0,
        'Storable'            => 0,
        'version'             => 0,
    },
    add_to_cleanup => ['YAGL-*'],
);

$builder->create_build_script();
