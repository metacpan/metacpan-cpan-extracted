use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Time::Duration::es',
    AUTHOR           => q{Biafra <biafra@cpan.org>},
    VERSION_FROM     => 'lib/Time/Duration/es.pm',
    ABSTRACT_FROM    => 'lib/Time/Duration/es.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.32,
    },
    PREREQ_PM => {
        'Time::Duration' => 1.02,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Duration-es-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/biafra/Time-Duration-es.git',
                web  => 'https://github.com/biafra/Time-Duration-es',
            },
        }})
    : ()
    ),
);
