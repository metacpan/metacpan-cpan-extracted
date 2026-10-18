use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    ABSTRACT           => 'update Uptime Kuma push monitors',
    AUTHOR             => 'Sven Kirmess <sven.kirmess@kzone.ch>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    DISTNAME  => 'WebService-UptimeKuma-Push',
    EXE_FILES => [
        'bin/kuma-push',
    ],
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => '5.010',
    NAME             => 'WebService::UptimeKuma::Push',
    PREREQ_PM        => {
        Carp             => 0,
        'File::Basename' => 0,
        'Getopt::Long'   => 0,
        'HTTP::Tiny'     => '0.025',
        'JSON::PP'       => 0,
        'Scalar::Util'   => 0,
        'Time::HiRes'    => 0,
        strict           => 0,
        warnings         => 0,
    },
    TEST_REQUIRES => {
        Cwd          => 0,
        Exporter     => 0,
        'File::Spec' => 0,
        'Test::More' => '0.88',
        lib          => 0,
    },
    VERSION => '0.002',
    test    => {
        TESTS => 't/*.t',
    },
);

my %FallbackPrereqs = (
    Carp             => 0,
    Cwd              => 0,
    Exporter         => 0,
    'File::Basename' => 0,
    'File::Spec'     => 0,
    'Getopt::Long'   => 0,
    'HTTP::Tiny'     => '0.025',
    'JSON::PP'       => 0,
    'Scalar::Util'   => 0,
    'Test::More'     => '0.88',
    'Time::HiRes'    => 0,
    lib              => 0,
    strict           => 0,
    warnings         => 0,
);

if ( !eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
    delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);

# vim: ts=4 sts=4 sw=4 et: syntax=perl
