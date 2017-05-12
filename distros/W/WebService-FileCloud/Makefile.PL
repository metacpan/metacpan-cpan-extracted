use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'WebService::FileCloud',
	       VERSION_FROM => 'lib/WebService/FileCloud.pm',
	       ABSTRACT_FROM => 'lib/WebService/FileCloud.pod',
	       AUTHOR => ['Mitch McCracken <mrmccrac@gmail.com>'],
	       PREREQ_PM => {'JSON' => 0,
			     'LWP::UserAgent' => 0,
			     'HTTP::Message' => 0},
	       BUILD_REQUIRES => {'Test::More' => 0,
				  'Test::Pod' => 0,
				  'Test::Pod::Coverage' => 0} );
