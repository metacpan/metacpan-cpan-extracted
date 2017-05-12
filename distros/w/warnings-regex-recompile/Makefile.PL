use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'warnings::regex::recompile',
    AUTHOR           => q{Kiran Rajendrasa Pawar <pawark86@gmail.com>},
    VERSION_FROM     => 'lib/warnings/regex/recompile.pm',
    ABSTRACT_FROM    => 'lib/warnings/regex/recompile.pm',
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
        're'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'warnings-regex-recompile-*' },
);
