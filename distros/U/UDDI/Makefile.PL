require 5.6.0;

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'UDDI',
    'VERSION_FROM' => 'UDDI.pm',
    PREREQ_PM    => {
		     'LWP' => 5.4,
		     'XML::Parser' => 2,
                    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
