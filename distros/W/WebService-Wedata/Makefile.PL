use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Wedata',
    AUTHOR              => 'Tsutomu KOYACHI <rtk2106@gmail.com>',
    VERSION_FROM        => 'lib/WebService/Wedata.pm',
    ABSTRACT_FROM       => 'lib/WebService/Wedata.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Wedata-*' },
);
