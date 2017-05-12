# $Id: Build.PL,v 1.1 2004/12/27 03:01:15 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'XML::Generator::vCard::RDF',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/XML/Generator/vCard/RDF.pm',
			       license           => 'perl',
			       requires => {
				   'XML::Generator::vCard::Base' => '>= 1.0',
				   'Text::vCard'                 => '>= 1.9',
				   'Digest::SHA1'                => '>= 2.10',
				   'Encode'                      => '>= 1.09',
				   'Memoize'                     => '',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
