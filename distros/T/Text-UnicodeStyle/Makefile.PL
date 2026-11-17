use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Text::UnicodeStyle',
    VERSION_FROM => 'lib/Text/UnicodeStyle.pm',
    ABSTRACT     => 'Replace Latin letters with lookalike Unicode characters',
    AUTHOR       => 'Alexander Sapozhnikov <shoorick@cpan.org>',

    LICENSE      => 'mit',

    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shoorick/substitute-letters.git',
                web  => 'https://github.com/shoorick/substitute-letters',
            },
            bugtracker => {
                web => 'https://github.com/shoorick/substitute-letters/issues',
            },
        },
    },

    PREREQ_PM => {
        'Exporter' => 0,
    },

    test => { TESTS => 't/*.t' },

    EXE_FILES => ['bin/substitute-letters'],
);
