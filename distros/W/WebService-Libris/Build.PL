use strict;
use warnings;
use Module::Build;
use 5.010;

my $build = Module::Build->new(
    create_readme      => 0,
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'WebService::Libris',
    dist_author        => 'Moritz Lenz',
    dist_abstract      => 'Programmatic access to book meta data from libris.kb.se',
    dist_version_from  => 'lib/WebService/Libris.pm',
    requires => {
        perl        => '5.010',
        Mojolicious => '4.063',
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
