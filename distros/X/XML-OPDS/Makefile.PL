use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'XML::OPDS',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/XML/OPDS.pm',
    ABSTRACT_FROM    => 'lib/XML/OPDS.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Differences' => 0,
    },
    PREREQ_PM => {
                  'Moo' => 1,
                  'Type::Tiny' => 1,
                  'XML::Atom' => 0.41,
                  'DateTime' => 0,
                  'DateTime::Format::RFC3339' => 0,
                  'Data::Page' => 0,
                  'URI' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-OPDS-*' },
    META_MERGE => {
                   resources => {
                                 repository => 'https://github.com/melmothx/libxml-opds-perl',
                                 homepage => 'http://amusewiki.org',
                                 x_IRC => 'irc://chat.freenode.net/#amusewiki',
                                 x_WebIRC => 'https://webchat.freenode.net/?channels=#amusewiki',
                                },
                  },

);
