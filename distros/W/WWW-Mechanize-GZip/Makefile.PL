use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Mechanize::GZip',
    AUTHOR              => 'Peter Giessner <cardb@planet-elektronik.de>',
    VERSION_FROM        => 'lib/WWW/Mechanize/GZip.pm',
    ABSTRACT_FROM       => 'lib/WWW/Mechanize/GZip.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Compress::Zlib' => 0,
	'WWW::Mechanize' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Mechanize-GZip-*' },
);
