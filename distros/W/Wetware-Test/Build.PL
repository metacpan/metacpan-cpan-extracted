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
    module_name         => 'Wetware::Test',
    license             => 'perl',
    dist_author         => '"drieux" <"drieux [AT] @wetware.com">',
    dist_version_from   => 'lib/Wetware/Test.pm',
    requires      => {
        'File::Basename'    => 0,
        'File::Spec'        => 0,
        'FindBin'           => 0,
        'Test::More'        => 0,
        'Test::Class::Load' => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup      => [ 'Wetware-Test-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
