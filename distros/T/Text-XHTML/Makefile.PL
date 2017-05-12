use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::XHTML',
    AUTHOR              => 'Eugene Grigoriev <eugene.grigoriev@gmail.com>',
    VERSION_FROM        => 'lib/Text/XHTML.pm',
    ABSTRACT_FROM       => 'lib/Text/XHTML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-XHTML-*' },
);
