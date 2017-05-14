use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ZHOUYI::ZhanPu',
    AUTHOR           => q{ORANGE <bollwarm@ijz.me>},
    VERSION_FROM     => 'lib/ZHOUYI/ZhanPu.pm',
    ABSTRACT_FROM    => 'lib/ZHOUYI/ZhanPu.pm',
    LICENSE          => 'Perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'ZHOUYI'          => 0.07,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ZHOUYI-ZhanPu-*' },
);
