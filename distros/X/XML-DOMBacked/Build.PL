use strict;
use Module::Build;

Module::Build->new(
		   module_name     => 'XML::DOMBacked',
		   license         => 'perl',
		   requires        => {
				       'perl' => 5.008,
				       'XML::LibXML' => 0,
				       'LWP::UserAgent' => 0,
				      },
		   build_requires => {
				      'Test::More' => 0,
				     },
		   create_makefile_pl => 'traditional',
		  )->create_build_script;
