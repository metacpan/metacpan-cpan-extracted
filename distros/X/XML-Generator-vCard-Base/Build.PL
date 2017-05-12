# $Id: Build.PL,v 1.1 2004/12/27 02:53:59 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'XML::Generator::vCard::Base',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/XML/Generator/vCard/Base.pm',
			       license           => 'perl',
			       requires => {
				   'XML::SAX::Base' => '>= 1.04',
				   'Encode'         => '>= 1.09',
				   'URI'            => '>= 1.35',
				   'Memoize'        => '',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
