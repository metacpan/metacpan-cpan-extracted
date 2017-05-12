use 5.008_005;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'cet',
    AUTHOR           => q{Andreas Lund <floyd@atc.no>, C Hutchinson <taint@cpan.org>},
    VERSION_FROM     => 'lib/cet.pm',
    EXE_FILES      => ['cet'],
    ABSTRACT_FROM    => 'lib/cet.pm',
    LICENSE          => 'artistic',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008_005,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    'File::Spec'     => 0,
    'Term::ReadLine' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'cet-*' },
);
