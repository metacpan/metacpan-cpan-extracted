use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Yahoo::KeywordExtractor',
    AUTHOR              => 'Nick Gerakines <nick@gerakines.net>',
    VERSION_FROM        => 'lib/WWW/Yahoo/KeywordExtractor.pm',
    ABSTRACT_FROM       => 'lib/WWW/Yahoo/KeywordExtractor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'LWP::UserAgent' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Yahoo-KeywordExtractor-*' },
);
