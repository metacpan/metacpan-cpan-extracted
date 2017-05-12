require 5.004;

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Unicode::String',
    'VERSION_FROM' => 'String.pm',
    'PREREQ_PM'    => {	
	                 'MIME::Base64' => 2.00,
		      },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
