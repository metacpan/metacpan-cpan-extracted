use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Wetware::Test::CreateTestSuite',
    license             => 'perl',
    dist_author         => '"drieux" <"drieux [AT] @wetware.com">',
    dist_version_from   => 'lib/Wetware/Test/CreateTestSuite.pm',
    requires => {
        'Carp'           => 0,
        'English'        => 0,
        'File::Basename' => 0,
        'File::Find'     => 0,
        'File::Path'     => 0,
        'File::Spec'     => 0,
        'ReadOnly'       => 0,
        'Wetware::Test'  => 0.06,
        'Wetware::CLI'   => 0.06,
    },
    build_requires => {
        'Test::More'    => 0,
        'Test::Compile' => 0.08,
    },
    add_to_cleanup      => [ 'Wetware-Test-CreateTestSuite-*' ],
);

$builder->create_build_script();
