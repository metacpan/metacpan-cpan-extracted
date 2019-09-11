use 5.016000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test2::MojoX',
    AUTHOR           => q{Ilya 'elcamlost' Rassadin <elcamlost@protonmail.com>},
    VERSION_FROM     => 'lib/Test2/MojoX.pm',
    ABSTRACT_FROM    => 'lib/Test2/MojoX.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::Suite' => '0.000126',
    },
    PREREQ_PM => {
        'Mojolicious' => '8.0',
        'Test2::Suite' => '0.000126',
    },
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {
            directory => [qw(examples t)],
        },
        prereqs   => {runtime => {requires => {perl => '5.016000'}}},
        resources => {
            bugtracker => {web => 'https://github.com/elcamlost/Test2-MojoX/issues'},
            homepage   => 'https://mojolicious.org',
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository => {
                type => 'git',
                url  => 'git@github.com:elcamlost/Test2-MojoX.git',
                web  => 'https://github.com/elcamlost/Test2-MojoX',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test2-MojoX-*' },
);
