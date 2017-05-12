use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::VirusTotal',
    AUTHOR           => q{Michelle Sullivan <michelle@sorbs.net>},
    VERSION_FROM     => 'lib/WebService/VirusTotal.pm',
    ABSTRACT         => 'lib/WebService/VirusTotal.pm',
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
        'LWP::UserAgent'	=> 6.0,
        'JSON'			=> 2.0,
	'Digest::SHA'		=> 5.7,
	'Digest::MD5'		=> 2.5,
	'List::Util'		=> 1.25,
	'Carp'			=> 1.26,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-VirusTotal-*' },
);
