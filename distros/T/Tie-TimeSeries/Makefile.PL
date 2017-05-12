use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tie::TimeSeries',
    AUTHOR           => q{Takahiro Onodera <ong at garakuta.net>},
    VERSION_FROM     => 'lib/Tie/TimeSeries.pm',
    ABSTRACT_FROM    => 'lib/Tie/TimeSeries.pm',
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
        'Carp'           => 0,
        'Tie::Hash'      => 0,
        'Search::Binary' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tie-TimeSeries-*' },
);
