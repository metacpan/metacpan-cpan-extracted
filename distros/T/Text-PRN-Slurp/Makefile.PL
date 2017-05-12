use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::PRN::Slurp',
    AUTHOR           => q{Rakesh Kumar Shardiwal <rakesh.shardiwal@gmail.com>},
    VERSION_FROM     => 'lib/Text/PRN/Slurp.pm',
    ABSTRACT_FROM    => 'lib/Text/PRN/Slurp.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'IO::File' => 0,
        'IO::Scalar' => 0,
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::CheckManifest' => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Warn' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-PRN-Slurp-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'git@github.com:shardiwal/cpan-Text-PRN-Slurp.git',
                web => 'https://github.com/shardiwal/cpan-Text-PRN-Slurp'
            },
        },
    },
);
