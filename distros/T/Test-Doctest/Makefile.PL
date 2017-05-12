use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::Doctest',
    AUTHOR           => q{Andrei Fyodorov <afyodorov@cpan.org>},
    VERSION_FROM     => 'lib/Test/Doctest.pm',
    ABSTRACT_FROM    => 'lib/Test/Doctest.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Data::Dumper' => 0,
        'Exporter' => 0,
        'Pod::Parser' => 0,
        'Carp' => 0,
        'Test::Builder' => 0,
        'Test::Deep' => '0.120',
        'File::Spec::Functions' => 0,
        'Module::Metadata' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Doctest-*' },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/mkllnk/PerlDoctest.git',
                web => 'https://github.com/mkllnk/PerlDoctest',
            },
            bugtracker => {
               web => 'https://github.com/mkllnk/PerlDoctest/issues',
            },
        }
    }
);
