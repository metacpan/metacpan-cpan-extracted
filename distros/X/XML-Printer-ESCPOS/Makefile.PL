use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'XML::Printer::ESCPOS',
    AUTHOR           => q{Dominic Sonntag <dominic@s5g.de>},
    VERSION_FROM     => 'lib/XML/Printer/ESCPOS.pm',
    ABSTRACT_FROM    => 'lib/XML/Printer/ESCPOS.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'                    => 0,
        'Test::CheckManifest'           => 0,
        'Test::Pod::Coverage'           => 0,
        'Test::Pod'                     => 0,
        'Test::Deep'                    => 0,
        'Test::Deep::UnorderedPairs'    => 0,
    },
    PREREQ_PM => {
        'XML::Parser'       => 0,
        'Text::Wrapper'     => 0,
        'GD'                => 0,
        'List::MoreUtils'   => 0,
        'Array::Utils'      => 0,
    },
    META_MERGE => {
        resources => {
            repository => {
                url  => 'https://github.com/sonntagd/XML-Printer-ESCPOS.git',
                web  => 'https://github.com/sonntagd/XML-Printer-ESCPOS',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/sonntagd/XML-Printer-ESCPOS/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-Printer-ESCPOS-*' },
);
