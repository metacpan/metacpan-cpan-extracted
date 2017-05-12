use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::EveOnline',
    AUTHOR              => 'Chris Carline <chris@carline.org>',
    VERSION_FROM        => 'lib/WebService/EveOnline.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'XML::Simple' => 0,
        'Storable' => 0,
        'Time::Local' => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-EveOnline-*' },
);
