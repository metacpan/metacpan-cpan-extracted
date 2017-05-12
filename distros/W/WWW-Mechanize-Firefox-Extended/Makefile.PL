use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Mechanize::Firefox::Extended',
    AUTHOR           => q{Hoe-Kit Chew <hoekit at gmail dot com>},
    VERSION_FROM     => 'lib/WWW/Mechanize/Firefox/Extended.pm',
    ABSTRACT_FROM    => 'lib/WWW/Mechanize/Firefox/Extended.pm',
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
        'WWW::Mechanize::Firefox' => 0,
        'Time::HiRes' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Mechanize-Firefox-Extended-*' },
);
