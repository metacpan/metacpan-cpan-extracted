use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tk::Tree::XML',
    AUTHOR              => 'José Santos <santos.swdev@gmail.com>',
    VERSION_FROM        => 'lib/Tk/Tree/XML.pm',
    ABSTRACT_FROM       => 'lib/Tk/Tree/XML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tk-Tree-XML-*' },
);
