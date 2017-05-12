use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Atom::Filter',
    AUTHOR              => 'Mark Paschal <markpasc@markpasc.org>',
    VERSION_FROM        => 'lib/XML/Atom/Filter.pm',
    ABSTRACT_FROM       => 'lib/XML/Atom/Filter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Atom'  => '0.20',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Atom-Filter-*' },
);
