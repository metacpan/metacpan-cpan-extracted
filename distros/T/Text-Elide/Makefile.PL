use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Elide',
    AUTHOR              => 'Ave Wrigley <ave.wrigley@ave.wrigley.name>',
    VERSION_FROM        => 'lib/Text/Elide.pm',
    ABSTRACT_FROM       => 'lib/Text/Elide.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'version'               => 0,
        'Smart::Comments'       => 0,
        'Readonly'              => 0,
        'List::Util'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Elide-*' },
);
