use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Mechanize::Tor',
    AUTHOR           => q{spebern <bernhard@specht.net>},
    VERSION_FROM     => 'lib/WWW/Mechanize/Tor.pm',
    ABSTRACT_FROM    => 'lib/WWW/Mechanize/Tor.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'WWW::Mechanize'      => 0,
        'LWP::UserAgent::Tor' => 0,
        'File::Which'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Mechanize-Tor-*' },
);
