use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'yEd::Document',
    AUTHOR           => q{Heiko Finzel <heikofinzel@googlemail.com>},
    VERSION_FROM     => 'lib/yEd/Document.pm',
    ABSTRACT_FROM    => 'lib/yEd/Document.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'XML::LibXML'       => 1.70,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'yEd-Document-*' },
);
