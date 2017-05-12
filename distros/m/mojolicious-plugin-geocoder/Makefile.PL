use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::GeoCoder',
    AUTHOR           => q{Rohit Deshmukh <raigad1630@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/GeoCoder.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/GeoCoder.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious'           => 0,
        'Geo::Coder::Google'    => 0
    },
    META_MERGE  => {
        "meta-spec" => { version => 2 },
        resources   => {
                    "bugtracker" => {
                               "web" => "https://github.com/raigad/mojolicious-plugin-geocoder/issues"
                        },
                    "homepage" => "http://search.cpan.org/~raigad/mojolicious-plugin-geocoder/",
                    repository  => {
                                type => 'git',
                                url => 'git://github.com/raigad/mojolicious-plugin-geocoder.git',
                                web => 'https://github.com/raigad/mojolicious-plugin-geocoder',
                    },
    },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-GeoCoder-*' },
);
