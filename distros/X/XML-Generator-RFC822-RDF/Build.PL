# $Id: Build.PL,v 1.5 2004/12/22 16:51:06 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'XML::Generator::RFC822::RDF',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/XML/Generator/RFC822/RDF.pm',
			       license           => 'perl',
			       requires => {
				   'XML::SAX::Base' => '>= 1.04',
				   'Email::Simple'  => '>= 1.92',
				   'Email::Address' => '>= 1.80',
				   'Email::MIME'    => '>= 1.82',
				   'Digest::SHA1'   => '>= 2.10',
				   'Encode'         => '>= 1.09',
				   'Date::Parse'    => '>= 2.27',
				   'Date::Format'   => '>= 2.20',
				   'MIME::Words'    => '>= 3.03',
				   'Memoize'        => '',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
