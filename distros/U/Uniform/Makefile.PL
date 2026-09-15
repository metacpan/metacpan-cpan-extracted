use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Uniform',
    AUTHOR           => 'Joshua S. Day <HAX@cpan.org>',
    VERSION_FROM     => 'lib/Uniform.pm',
    ABSTRACT_FROM    => 'lib/Uniform.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010000',

    PREREQ_PM => {
        'Exporter' => '5.57',
    },

    TEST_REQUIRES => {
        'Test::More'      => '0.88',
        'Test::Deep'      => '0',
        'Test::Exception' => '0',
    },


    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Uniform',
                web  => 'https://github.com/haxmeister/perl-Uniform',
            },
            bugtracker => {
                web  => 'https://github.com/haxmeister/perl-Uniform/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Uniform-*' },
);
