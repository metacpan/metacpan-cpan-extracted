use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'WWW::Plurk',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/WWW/Plurk.pm',
    ABSTRACT_FROM => 'lib/WWW/Plurk.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Data::Dumper'           => 0,
        'DateTime::Format::Mail' => 0,
        'Getopt::Long'           => 0,
        'HTML::Tiny'             => 0,
        'HTTP::Cookies'          => 0,
        'JSON'                   => '2.00',
        'LWP::UserAgent'         => 0,
        'Math::Base36'           => 0,
        'Test::Deep'             => 0,
        'Test::More'             => 0,
        'Time::Piece'            => 0,
    },
    EXE_FILES => ['bin/plurk'],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Plurk-*' },
);
