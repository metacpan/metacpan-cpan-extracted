use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::RSS::FromAtom',
    AUTHOR              => 'Marcus Thiesen <marcus@thiesen.org>',
    VERSION_FROM        => 'lib/XML/RSS/FromAtom.pm',
    ABSTRACT_FROM       => 'lib/XML/RSS/FromAtom.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::Accessor' => 0,
	
        'DateTime' => 0,
        'DateTime::Format::ISO8601' => 0,
        'DateTime::Format::Mail' => 0,

        'XML::Atom::Syndication' => 0,
        'XML::RSS' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-RSS-FromAtom-*' },
);
