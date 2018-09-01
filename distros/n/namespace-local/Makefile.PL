use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'namespace::local',
    AUTHOR           => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM     => 'lib/namespace/local.pm',
    ABSTRACT_FROM    => 'lib/namespace/local.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.98',
        'Test::Exception' => '0',
        'Scalar::Util' => 1,
    },
    PREREQ_PM => {
        'B::Hooks::EndOfScope' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/dallaylaen/namespace-local-perl/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/dallaylaen/namespace-local-perl.git',
                web => 'https://github.com/dallaylaen/namespace-local-perl',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'namespace-local-*' },
);
