use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Word::Rhymes',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Word/Rhymes.pm',
    ABSTRACT_FROM    => 'lib/Word/Rhymes.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES        => ['bin/rhyme'],
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/word-rhymes/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/word-rhymes.git',
                web => 'https://github.com/stevieb9/word-rhymes',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'JSON'              => 0,
        'HTTP::Request'     => 0,
        'LWP::UserAgent'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Word-Rhymes-*' },
);
