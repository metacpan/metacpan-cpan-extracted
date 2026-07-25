use 5.014;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Wildling',
    VERSION_FROM     => 'lib/Wildling.pm',
    ABSTRACT         => 'Pattern based string generator library and CLI',
    AUTHOR           => 'Magnus Weinberg <magnus.weinberg@gmail.com>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.014',
    EXE_FILES        => ['bin/wildling.pl'],
    PREREQ_PM        => {},
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/dotmonk/wildling',
            bugtracker => {
                web => 'https://github.com/dotmonk/wildling/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/dotmonk/wildling.git',
                web  => 'https://github.com/dotmonk/wildling/tree/main/perl',
            },
        },
    },
    clean => { FILES => 'Wildling-*' },
);

1;
