use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'XML::GSA',
    AUTHOR           => q{Shemahmforash <shemahmforash@gmail.com>},
    VERSION_FROM     => 'lib/XML/GSA.pm',
    ABSTRACT_FROM    => 'lib/XML/GSA.pm',
    LICENSE          => 'GPL_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'  => 0,
    },
    PREREQ_PM => {
        'XML::Writer' => 0.623,
        'DateTime'    => 0,
        'Date::Parse' => 0,
    },
    META_MERGE          => {
        resources => {
            repository => 'https://github.com/Shemahmforash/xml-gsa',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-GSA-*' },
);
