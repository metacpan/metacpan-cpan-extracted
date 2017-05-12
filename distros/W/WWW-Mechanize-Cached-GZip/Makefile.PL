use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Mechanize::Cached::GZip',
    AUTHOR              => 'Peter Giessner <cardb@planet-elektronik.de>',
    VERSION_FROM        => 'lib/WWW/Mechanize/Cached/GZip.pm',
    ABSTRACT_FROM       => 'lib/WWW/Mechanize/Cached/GZip.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'WWW::Mechanize::GZip' => 0,
	'WWW::Mechanize::Cached' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Mechanize-Cached-GZip-*' },
);
