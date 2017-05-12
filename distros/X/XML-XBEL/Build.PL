# $Id: Build.PL,v 1.1 2005/03/26 18:46:37 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'XML::XBEL',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/XML/XBEL.pm',
			       license           => 'perl',
			       requires => {
				   'XML::LibXML'  => '>= 1.58',
				   'Date::Format' => '>= 0',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
