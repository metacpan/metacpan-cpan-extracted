use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Piwik::API',
    AUTHOR           => q{Stefan Hornburg <racke@linuxia.de>},
    VERSION_FROM     => 'lib/WWW/Piwik/API.pm',
    ABSTRACT_FROM    => 'lib/WWW/Piwik/API.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
                  Moo => 0,
                  'LWP::UserAgent' => 0,
                  'JSON::MaybeXS' => 0,
                  'LWP::Protocol::https' => 0,
                  'Type::Tiny' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Piwik-API-*' },

    META_MERGE => {
        resources => {
            repository  => 'https://github.com/interchange/WWW-Piwik-API.git',
            bugtracker => 'https://github.com/interchange/WWW-Piwik-API/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
