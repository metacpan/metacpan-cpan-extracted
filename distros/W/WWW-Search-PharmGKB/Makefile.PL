use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Search::PharmGKB',
    AUTHOR              => 'Arun Venkataraman <arvktr@gmail.com>',
    VERSION_FROM        => 'lib/WWW/Search/PharmGKB.pm',
    ABSTRACT_FROM       => 'lib/WWW/Search/PharmGKB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'SOAP::Lite' => 0,
	'English'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Search-PharmGKB-*' },
);
