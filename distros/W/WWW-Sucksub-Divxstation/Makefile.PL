use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Sucksub::Divxstation',
    AUTHOR              => 'Timothée Foucart <timothee.foucart@apinc.org>',
    VERSION_FROM        => 'lib/WWW/Sucksub/Divxstation.pm',
    ABSTRACT_FROM       => 'lib/WWW/Sucksub/Divxstation.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         'Test::More' => '>=0.5',
         'WWW::Mechanize' => '>= 1.02',
         'DB_File'=> '>= 1.8',
         'HTTP::Cookies' => '>= 1.3',
	   'Carp' => '>= 1.0',
	   'Alias' => '>=2.3',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Sucksub-Divxstation-*' },
);
