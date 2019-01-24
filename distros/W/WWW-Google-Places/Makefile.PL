#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'WWW::Google::Places',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/Places.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/Places.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES       => {
        'Test::More'     => '1.001014',
        'Test::Internet' => '0.04',
    },
    PREREQ_PM => {
        'Moo'                    => '2.000000',
        'namespace::autoclean'   => '0.28',
        'File::Share'            => '0.25',
        'JSON'                   => '2.53',
        'WWW::Google::UserAgent' => '0.20',
        'Method::ParamValidator' => '0.10',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-Places-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::Places'                 => { file => 'lib/WWW/Google/Places.pm',               version => '0.34' },
            'WWW::Google::Places::Params'         => { file => 'lib/WWW/Google/Places/Params.pm',        version => '0.34' },
            'WWW::Google::Places::SearchResult'   => { file => 'lib/WWW/Google/Places/SearchResult.pm',  version => '0.34' },
            'WWW::Google::Places::DetailResult'   => { file => 'lib/WWW/Google/Places/DetailResult.pm',  version => '0.34' },
            'WWW::Google::Places::Geometry'       => { file => 'lib/WWW/Google/Places/Geometry.pm',      version => '0.34' },
            'WWW::Google::Places::Location'       => { file => 'lib/WWW/Google/Places/Location.pm',      version => '0.34' },
            'WWW::Google::Places::Photo'          => { file => 'lib/WWW/Google/Places/Photo.pm',         version => '0.34' },
            'WWW::Google::Places::Address'        => { file => 'lib/WWW/Google/Places/Address.pm',       version => '0.34' },
            'WWW::Google::Places::Review'         => { file => 'lib/WWW/Google/Places/Review.pm',        version => '0.34' },
            'WWW::Google::Places::Review::Aspect' => { file => 'lib/WWW/Google/Places/Review/Aspect.pm', version => '0.34' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-Places.git',
                web  => 'https://github.com/manwar/WWW-Google-Places',
            },
        }})
     : ()
    ),
);


package MY;
use File::ShareDir::Install 'postamble';
