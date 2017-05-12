use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::OkiLab::ExtractPlace',
    AUTHOR              => 'Makio Tsukamoto <tsukamoto@gmail.com>',
    VERSION_FROM        => 'lib/WebService/OkiLab/ExtractPlace.pm',
    ABSTRACT_FROM       => 'lib/WebService/OkiLab/ExtractPlace.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::ErrorHandler' => 0,
        'LWP::UserAgent' => 0,
        'JSON'       => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-OkiLab-ExtractPlace-*' },
);
