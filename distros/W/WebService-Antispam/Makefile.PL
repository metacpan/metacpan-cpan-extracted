use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Antispam',
    AUTHOR           => q{CleanTalk <welcome@cleantalk.ru>},
    VERSION_FROM     => 'lib/WebService/Antispam.pm',
    ABSTRACT_FROM    => 'lib/WebService/Antispam.pm',
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
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'JSON::XS'  => 0, 
        'LWP::UserAgent'  => 0, 
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Antispam-*' },
);
