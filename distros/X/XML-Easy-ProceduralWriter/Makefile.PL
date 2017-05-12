use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Easy::ProceduralWriter',
    AUTHOR              => 'Mark Fowler <mark@twoshortplanks.com>',
    VERSION_FROM        => 'lib/XML/Easy/ProceduralWriter.pm',
    ABSTRACT_FROM       => 'lib/XML/Easy/ProceduralWriter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'XML::Easy' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Easy-ProceduralWriter*' },
);
