use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ioqwerty',
    DISTNAME         => 'ioqwerty',
    VERSION_FROM     => 'lib/ioqwerty.pm',
    ABSTRACT         => 'Name reservation for ioqwerty',
    AUTHOR           => 'ioqwerty <ping@ioqwerty.com>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://ioqwerty.com',
            repository => {
                type => 'git',
                url  => 'https://github.com/ioqwerty/ioqwerty.git',
                web  => 'https://github.com/ioqwerty/ioqwerty',
            },
            bugtracker => {
                web => 'https://github.com/ioqwerty/ioqwerty/issues',
            },
        },
    },
);
