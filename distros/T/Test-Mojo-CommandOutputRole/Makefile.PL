use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Mojo::CommandOutputRole',
    AUTHOR              => 'Mirko Westermeier <mirko@westermeier.de>',
    VERSION_FROM        => 'lib/Test/Mojo/CommandOutputRole.pm',
    MIN_PERL_VERSION    => '5.20.0',
    PREREQ_PM           => {
        'Mojolicious'       => '8.06',
        'Capture::Tiny'     => '0.48',
        'Role::Tiny'        => '2.000006',
    },
    META_MERGE          => {resources => {
        bugtracker  => 'https://github.com/memowe/Test-Mojo-CommandOutputRole/issues',
        repository  => 'https://github.com/memowe/Test-Mojo-CommandOutputRole',
    }},
    test                => {TESTS => 't/*.t'}
);
