use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Pretty',
    AUTHOR              => 'Eugene Grigoriev <eugene.grigoriev@gmail.com>',
    VERSION_FROM        => 'lib/Text/Pretty.pm',
    ABSTRACT_FROM       => 'lib/Text/Pretty.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Types'      => '0.1',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Pretty-*' },
);
