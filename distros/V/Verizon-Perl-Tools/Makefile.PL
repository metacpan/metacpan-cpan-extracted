use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Verizon',
    DISTNAME         => 'Verizon-Perl-Tools',
    AUTHOR           => q{Jason Goth <jason@gothtx.com>},
    VERSION          => '0.1.04',
    EXE_FILES        => ['bin/ecloud.pl','bin/vcc.pl', 'bin/vcs.pl' ],
    ABSTRACT         => 'Perl Modules for using Verizon Cloud offerings',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Verizon-Perl-Tools-*' },
);
