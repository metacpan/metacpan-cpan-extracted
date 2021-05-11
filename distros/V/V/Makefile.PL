#! usr/bin/perl -w
use v5.10.1;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'V',
    VERSION_FROM  => 'lib/V.pm',
    ABSTRACT_FROM => 'lib/V.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',

    BUILD_REQUIRES => {
        'Test::More'     => 0,
        'Test::Fatal'    => 0,
        'Test::Warnings' => 0,
    },
    PREREQ_PM => { 'version' => 0.77 },

    MIN_PERL_VERSION => '5.010001',
    LICENSE          => 'perl_5',
    META_ADD         => {
        'meta-spec' => { version => 2 },
        'resources' => {
            homepage   => 'https://github.com/abeltje/V',
            repository => {
                type => 'git',
                url  => 'https://github.com/abeltje/V.git',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
