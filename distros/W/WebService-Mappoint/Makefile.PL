use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'	=> 'WebService::Mappoint',
	      ($[ >= 5.005) ?
	      ( AUTHOR   => 'Herald van der Breggen and Claudio Garcia',
		ABSTRACT => 'Easy to use API to Microsoft Mappoint web service' ) : (),
	      'VERSION_FROM' => 'Mappoint.pm',
	      'PREREQ_PM'    => {
				 SOAP::Lite          => '0',
				 MIME::Base64        => '0',
				 Test::More          => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	     );
