use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Types::PerlVersion',
    AUTHOR             => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM       => 'lib/Types/PerlVersion.pm',
    ABSTRACT_FROM      => 'lib/Types/PerlVersion.pm',
    LICENSE            => 'perl',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Exception' => 0,
        'Test::More'      => 0,
    },
    PREREQ_PM => {
        'Perl::Version' => 0,
        'Type::Tiny'    => 0,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Types-PerlVersion-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Sysnix/p5-Types-PerlVersion.git',
            bugtracker =>
              'https://github.com/Sysnix/p5-Types-PerlVersion/issues',
        },
    },
);
