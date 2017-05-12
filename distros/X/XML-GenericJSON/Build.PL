#!perl -w

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'XML::GenericJSON',
    license           => 'bsd',
    dist_author       => 'Mark Howe <melonman@cpan.org>',
	dist_abstract	  => 'for turning XML into JSON, preserving as much XMLness as possible.',
    dist_version_from => 'lib/XML/GenericJSON.pm',
    Build_requires    => { 'Test::More' => 0, },
    requires          => {
        'XML::LibXML' => '1.58',
	    'JSON::XS' => '0',
    },
    recommends => {
        'Test::Pod'           => '1.14',
        'Test::Pod::Coverage' => '1.04',
    },
    add_to_cleanup     => ['XML-GenericJSON-*'],
    create_makefile_pl => 'passthrough'
);

$builder->create_build_script();
