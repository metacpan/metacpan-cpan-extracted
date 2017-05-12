#!perl -w

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Xcruciate',
    license           => 'bsd',
    dist_author       => 'Mark Howe <melonman@cpan.org>',
	dist_abstract	  => 'libraries for perl scripts in and around the Xcruciate server project',
    dist_version_from => 'lib/Xcruciate.pm',
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'perl' => '5.6.1',
		'Carp' => '1.0',
		'XML::LibXSLT' => '1.58',
		'Time::gmtime'=> '1',
    },
    recommends => {
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    add_to_cleanup     => ['Xcruciate-*'],
    create_makefile_pl => 'passthrough'
);

$builder->create_build_script();
