use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test2::Tools::Expressive',
    AUTHOR           => q{Andy Lester <andy@petdance.com>},
    VERSION_FROM     => 'lib/Test2/Tools/Expressive.pm',
    ABSTRACT_FROM    => 'lib/Test2/Tools/Expressive.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'parent'                => 0,
        'Test2::Suite'          => 0,
        'Test2::Tools::Explain' => 0.02,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test2-Tools-Expressive-*' },
);
