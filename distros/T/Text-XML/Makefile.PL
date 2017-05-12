use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::XML',
    AUTHOR              => 'Eugene Grigoriev <eugene.grigoriev@gmail.com>',
    VERSION_FROM        => 'lib/Text/XML.pm',
    ABSTRACT_FROM       => 'lib/Text/XML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Types'      => 0.1,
        'Text::Pretty' => '0.1.0'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-XML-*' },
);
