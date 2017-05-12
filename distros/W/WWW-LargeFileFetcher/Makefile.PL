use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::LargeFileFetcher',
    AUTHOR              => 'Zhang Jun <jzhang533@gmail.com>',
    VERSION_FROM        => 'lib/WWW/LargeFileFetcher.pm',
    ABSTRACT_FROM       => 'lib/WWW/LargeFileFetcher.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.64,
        'LWP::UserAgent' => 2.033,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-LargeFileFetcher-*' },
);
