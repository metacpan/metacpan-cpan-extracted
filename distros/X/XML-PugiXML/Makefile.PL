use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::pugixml;

WriteMakefile(
    NAME             => 'XML::PugiXML',
    VERSION_FROM     => 'lib/XML/PugiXML.pm',
    ABSTRACT         => 'Perl binding for pugixml C++ XML parser',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    CC               => 'c++',
    LD               => 'c++',
    XSOPT            => '-C++',

    CCFLAGS          => '-std=c++11 -Wall ' . Alien::pugixml->cflags,
    OPTIMIZE         => '-O2',

    INC              => '-I.',
    LIBS             => [ Alien::pugixml->libs ],

    clean            => { FILES => 'PugiXML.c' },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Alien::pugixml'      => 0,
    },
    BUILD_REQUIRES => {
        'Alien::pugixml' => 0,
    },
    PREREQ_PM => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/vividsnow/perl5-xml-pugixml.git',
                web  => 'https://github.com/vividsnow/perl5-xml-pugixml',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-xml-pugixml/issues',
            },
        },
    },
);
