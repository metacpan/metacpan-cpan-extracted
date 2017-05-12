use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Tokenize::Indented',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/Text/Tokenize/Indented.pm',
    ABSTRACT_FROM    => 'lib/Text/Tokenize/Indented.pm',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/Text-Tokenize-Indented.git',
               web  => 'https://github.com/Vivtek/Text-Tokenize-Indented',
            },
        },
    },
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
        'Iterator::Simple' => 0,
        'Iterator::Simple::Lookahead' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Tokenize-Indented-*' },
);
