use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Win32::RunAsAdmin',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/Win32/RunAsAdmin.pm',
    ABSTRACT_FROM    => 'lib/Win32/RunAsAdmin.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    EXE_FILES           => [ qw(script/elev) ],
    PREREQ_PM => {
        'Devel::PL_origargv' => 0,
        'Win32::OLE' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/Win32-RunAsAdmin.git',
               web  => 'https://github.com/Vivtek/Win32-RunAsAdmin',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Win32-RunAsAdmin-*' },
);
