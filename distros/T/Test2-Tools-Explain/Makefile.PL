use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test2::Tools::Explain',
    AUTHOR           => q{Andy Lester <andy@petdance.com>},
    VERSION_FROM     => 'lib/Test2/Tools/Explain.pm',
    ABSTRACT_FROM    => 'lib/Test2/Tools/Explain.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'parent'       => 0,
        'Test2::Suite' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test2-Tools-Explain-*' },
);
