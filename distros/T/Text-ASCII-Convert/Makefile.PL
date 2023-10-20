use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::ASCII::Convert',
    VERSION_FROM     => 'lib/Text/ASCII/Convert.pm',
    ABSTRACT_FROM    => 'lib/Text/ASCII/Convert.pm',
    AUTHOR           => 'Kent Oyer <kent@mxguardian.net>',
    LICENSE          => 'GPL_3',
    MIN_PERL_VERSION => '5.008004',
    PREREQ_PM        => {
        'strict'   => 0,
        'warnings' => 0,
        'Encode' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mxguardian/Text-ASCII-Convert.git',
                web  => 'https://github.com/mxguardian/Text-ASCII-Convert',
            },
            bugtracker => {
                web => 'https://github.com/mxguardian/Text-ASCII-Convert/issues'
            },
            homepage   => 'https://github.com/mxguardian/Text-ASCII-Convert',
        },
    },
);