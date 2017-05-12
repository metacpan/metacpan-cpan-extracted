#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Wetware::CLI',
    license             => 'perl',
    dist_author         => '"drieux" <"drieux [AT] @wetware.com">',
    dist_version_from   => 'lib/Wetware/CLI.pm',
    requires      => {
    	'Getopt::Long' => 0,
    },
    build_requires => {
        'Test::More'               => 0,
        'Test::Perl::Critic'       => 0,
        'Wetware::Test'            => 0.04,
        'Wetware::Test::Suite'     => 0.04,
        'Wetware::Test::Utilities' => 0.02,
    },
    add_to_cleanup => [
        qw( *.tar.gz
            Wetware-CLI-*
            MANIFEST.bak
            )
    ],
    recursive_test_files => 1,
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
