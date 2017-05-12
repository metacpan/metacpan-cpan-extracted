use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => "Test::Numeric",
    license     => 'perl',
    requires    => {
        'Test::Builder'         => 0,
    },

    build_requires => {
        'Module::Build'         => 0,
        'Test::Builder::Tester' => 0,
        'Test::More'            => 0,
    },

    recommends => {
        'Pod::Coverage'         => 0,
	'Test::Inline'          => 0,
        'Test::Pod'             => 0,
    },

    create_makefile_pl => 'passthrough',
);

$build->create_build_script;
#$build->write_makefile;


# Create the test file for the pod in Numeric.pm
eval "use Test::Inline";
unless ( $@ ) {
    # Test::Inline is available - create the tests.
    system('pod2test lib/Test/Numeric.pm t/pod-inline.t');
}
