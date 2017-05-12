# Build.PL
# Use to build the package Tk::MTDial
our $VERSION = '0.001';
    
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name=> 'Tk::MTDial',
    dist_name  => 'Tk-MTDial',
    dist_author=> [
	'W. Luis Mochan <mochan@fis.unam.mx>',
	],
    dist_version_from => 'lib/Tk/MTDial.pm',
    license    => 'perl',
    release_status => 'stable', #stable, testing or unstable
    requires   => { 
	"Tk" => 0,
    },
    test_requires => {
	"Test::More" => 0,
	"Pod::Coverage::TrustPod" => 0,
    },
    configure_requires => {
	'Module::Build'                      => '0.4004',
    },
    add_to_cleanup  => [ 'Tk-MTDial-*'],
    create_makefile_pl => 'small',
    );
$builder->create_build_script();
