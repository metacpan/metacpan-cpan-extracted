use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::SimpleVaddrbook',
    AUTHOR              => 'Michael Tomuschat <michael.tomuschat@t-online.de>',
    VERSION_FROM        => 'lib/Text/SimpleVaddrbook.pm',
    ABSTRACT_FROM       => 'lib/Text/SimpleVaddrbook.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-SimpleVaddrbook-*' },
);
