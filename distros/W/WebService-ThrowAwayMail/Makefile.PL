use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'WebService::ThrowAwayMail',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/WebService/ThrowAwayMail.pm',
    ABSTRACT_FROM    => 'lib/WebService/ThrowAwayMail.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Module::Metadata' => '1.000033',
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::MockObject' => '1.20150527',
    },
    PREREQ_PM => {
        'Moo' => '2.003001',
        'MooX::LazierAttributes' => '0.13',
        'MooX::ValidateSubs' => '0.08',
        'Type::Tiny' => '1.000006',
        'HTTP::Tiny' => '0.054', 
        'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-ThrowAwayMail-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/WebService-ThrowAwayMail.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/WebService-ThrowAwayMail',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
