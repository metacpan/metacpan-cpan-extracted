use 5.006                     ;
use strict                    ;
use warnings FATAL => 'all'   ;
use ExtUtils::MakeMaker       ;

WriteMakefile(
    NAME             => 'WWW::PerlMonks',
    AUTHOR           => q{Harish Madabushi <harish.tmh@gmail.com>},
    VERSION_FROM     => 'lib/WWW/PerlMonks.pm',
    ABSTRACT_FROM    => 'lib/WWW/PerlMonks.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'       => 0     ,
    },
    PREREQ_PM => {
	'Carp'             => 0     ,
	'XML::Smart'       => 1.6   ,
	'HTTP::Request'    => 6.00  ,
	'LWP::UserAgent'   => 6.00  ,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-PerlMonks-*' },
);
