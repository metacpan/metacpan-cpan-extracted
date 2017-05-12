use 5.008004;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Text::Record::Deduper',
    VERSION_FROM  => 'lib/Text/Record/Deduper.pm', 
    PREREQ_PM     => {},
    ABSTRACT_FROM => 'lib/Text/Record/Deduper.pm',
    AUTHOR        => 'Kim Ryan',
    'LICENSE'     => 'perl'
);
