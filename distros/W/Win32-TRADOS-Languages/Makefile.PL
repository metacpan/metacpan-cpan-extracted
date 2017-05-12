use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Win32::TRADOS::Languages',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/Win32/TRADOS/Languages.pm',
    ABSTRACT_FROM    => 'lib/Win32/TRADOS/Languages.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    EXE_FILES           => [ qw(script/ttx-lang) ],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Getopt::Euclid' => 0,
        'Win32::RunAsAdmin' => 0.02,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/Win32-TRADOS-Languages.git',
               web  => 'https://github.com/Vivtek/Win32-TRADOS-Languages',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Win32-TRADOS-Languages-*' },
);
