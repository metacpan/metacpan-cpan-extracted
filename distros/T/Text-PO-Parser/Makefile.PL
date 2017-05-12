use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::PO::Parser',
    AUTHOR              => 'Cyprien Le Pannérer <cyplp@free.fr>',
    VERSION_FROM        => 'lib/Text/PO/Parser.pm',
    ABSTRACT_FROM       => 'lib/Text/PO/Parser.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-PO-Parser-*' },
);
