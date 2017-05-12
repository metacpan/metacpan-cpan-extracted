use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Search::UrbanDictionary',
    AUTHOR              => 'Nick Gerakines <nick@gerakines.net>',
    VERSION_FROM        => 'lib/WWW/Search/UrbanDictionary.pm',
    ABSTRACT_FROM       => 'lib/WWW/Search/UrbanDictionary.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'SOAP::Lite' => 0,
        'WWW::Search' => 0,
		'XML::Simple' => 0,
		'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Search-UrbanDictionary-*' },
);
