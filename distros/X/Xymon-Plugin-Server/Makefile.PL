use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Xymon::Plugin::Server',
    AUTHOR           => q{Toshimitsu FUJIWARA <tttfjw@gmail.com>},
    VERSION_FROM     => 'lib/Xymon/Plugin/Server.pm',
    ABSTRACT_FROM    => 'lib/Xymon/Plugin/Server.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Xymon-Plugin-Server-* t/tmp' },
);
