use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                   => 'Var::Mystic',
    AUTHOR                 => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM           => 'lib/Var/Mystic.pm',
    ABSTRACT_FROM          => 'lib/Var/Mystic.pm',
    PL_FILES               => {},
    LICENSE                => 'artistic2',
    MIN_PERL_VERSION       => 5.014,
    TEST_REQUIRES => {
        'Test::Effects'    => 0,
    },
    PREREQ_PM => {
        'Keyword::Declare' => 0,
        'Data::Dx'         => 0,
        'Variable::Magic'  => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                  => { FILES => 'Var-Mystic-*' },
);
