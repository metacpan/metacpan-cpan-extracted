use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Amuse',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Text/Amuse.pm',
    ABSTRACT_FROM    => 'lib/Text/Amuse.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Data::Dumper' => 0,
        'File::Spec'   => 0,
    },
    PREREQ_PM => {
        'File::Temp' => 0,
    },
    # EXE_FILES => [ 'bin/muse-quick.pl' ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Amuse-*' },
    META_MERGE => {
                   resources => {
                                 repository => 'https://github.com/melmothx/text-amuse',
                                 bugtracker => 'https://github.com/melmothx/text-amuse/issues',
                                 homepage => 'http://amusewiki.org',
                                 x_IRC => 'irc://chat.freenode.net/#amusewiki',
                                 x_WebIRC => 'https://webchat.freenode.net/?channels=#amusewiki',
                                },
                  },
);
