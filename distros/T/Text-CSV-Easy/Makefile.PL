use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::CSV::Easy',
    AUTHOR           => q{Tom Peters <weters@me.com>},
    VERSION_FROM     => 'lib/Text/CSV/Easy.pm',
    ABSTRACT_FROM    => 'lib/Text/CSV/Easy.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.96',
        'Test::Deep' => 0,
    },
    PREREQ_PM => { },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-CSV-Easy-*' },
);
