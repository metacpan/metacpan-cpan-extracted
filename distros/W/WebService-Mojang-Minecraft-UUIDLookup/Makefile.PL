use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Mojang::Minecraft::UUIDLookup',
    AUTHOR           => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM     => 'lib/WebService/Mojang/Minecraft/UUIDLookup.pm',
    ABSTRACT_FROM    => 'lib/WebService/Mojang/Minecraft/UUIDLookup.pm',
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
        'Data::UUID' => 0,
        'Moo' => 0,
        'LWP::UserAgent' => 0,
        'JSON' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Mojang-Minecraft-UUIDLookup-*' },
);
