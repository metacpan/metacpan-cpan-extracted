use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Trickster',
    AUTHOR           => 'Isaac Caldwell',
    VERSION_FROM     => 'lib/Trickster.pm',
    ABSTRACT         => 'A modern, battle-tested micro-framework for Perl web applications',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM        => {
        'Plack'              => '1.0047',
        'Plack::Request'     => 0,
        'Plack::Response'    => 0,
        'Plack::Middleware'  => 0,
        'JSON::PP'           => 0,
        'Encode'             => 0,
        'URI::Escape'        => 0,
        'Digest::SHA'        => 0,
        'Time::Piece'        => 0,
        'File::Path'         => 0,
        'File::Spec'         => 0,
        'Getopt::Long'       => 0,
    },
    EXE_FILES        => ['bin/trickster'],
    OPTIONAL_FEATURES => {
        templates => {
            description => 'Template engine support',
            requires => {
                'Text::Xslate' => '3.0',
            },
        },
    },
    TEST_REQUIRES    => {
        'Test::More'            => '0.98',
        'HTTP::Request::Common' => 0,
        'Plack::Test'           => 0,
        'File::Temp'            => 0,
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tricksterperl/trickster.git',
                web  => 'https://github.com/tricksterperl/trickster',
            },
        },
    },
);
