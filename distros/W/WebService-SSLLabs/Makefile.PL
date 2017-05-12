use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::SSLLabs',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/WebService/SSLLabs.pm',
    ABSTRACT_FROM    => 'lib/WebService/SSLLabs.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'parent' => 0,
    },
    PREREQ_PM => {
        'strict'           => 0,
        'warnings'         => 0,
        'URI::Escape'      => 3.30,
        'URI'              => 1.53,
        'JSON'             => 0,
        'LWP::UserAgent'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-SSLLabs-*' },
);
