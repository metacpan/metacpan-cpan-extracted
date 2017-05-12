use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::SmugMug::API',
    AUTHOR              => 'Paul Arthur <flowerysong00@yahoo.com>',
    VERSION_FROM        => 'lib/WWW/SmugMug/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/SmugMug/API.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'JSON' => 0,
        'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-SmugMug-API-*' },
);
