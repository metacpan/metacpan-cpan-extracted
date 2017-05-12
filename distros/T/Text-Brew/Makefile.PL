use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Brew',
    AUTHOR              => 'Keith C. Ivey <kcivey@cpcug.org>',
    VERSION_FROM        => 'lib/Text/Brew.pm',
    ABSTRACT_FROM       => 'lib/Text/Brew.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Brew-*' },
);
