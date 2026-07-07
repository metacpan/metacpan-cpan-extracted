use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Web3::Tiny',
    AUTHOR           => 'Alex Pepper <axpepper@gmail.com>',
    VERSION_FROM     => 'lib/Web3/Tiny.pm',
    ABSTRACT         => 'A small, dependency-light way to talk to Ethereum from Perl',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM        => {
        'Math::BigInt' => 0,
        'CryptX'       => '0.081',
        'HTTP::Tiny'   => 0,
        'JSON::PP'     => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/axpepper/Web3-Tiny.git',
                web  => 'https://github.com/axpepper/Web3-Tiny',
            },
        },
    },
    test => { TESTS => 't/*.t' },
);
