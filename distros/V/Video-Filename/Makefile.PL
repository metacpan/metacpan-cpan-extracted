use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Video::Filename',
    AUTHOR              => 'Behan Webster <behanw@websterwood.com>',
    VERSION_FROM        => 'lib/Video/Filename.pm',
    ABSTRACT_FROM       => 'lib/Video/Filename.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Debug::Simple' => 0,
        'Text::Roman' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Video-Filename-*' },
);
