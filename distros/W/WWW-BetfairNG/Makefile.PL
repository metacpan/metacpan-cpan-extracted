use 5.10.1;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::BetfairNG',
    AUTHOR             => 'Myrddin Wyllt <myrddinwyllt@tiscali.co.uk>',
    VERSION_FROM       => 'lib/WWW/BetfairNG.pm',
    ABSTRACT_FROM      => 'lib/WWW/BetfairNG.pm',
    LICENSE            => "perl_5",
    MIN_PERL_VERSION   => '5.010001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES     => {
		    'Test::More' => 0,
    },
    PREREQ_PM          => {
        'Carp'                   => 1.26,
	'Net::Ping'              => 0,
	'HTTP::Tiny'             => 0.049,
	'IO::Socket::SSL'        => 1.56,
        'Net::SSLeay'            => 1.49,
	'JSON::MaybeXS'          => 1.002002,
        'IO::Uncompress::Gunzip' => 2.060,
    },
);
