#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::URLShortener',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/URLShortener.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/URLShortener.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'                    => '2.000000',
        'namespace::clean'       => '0.24',
        'JSON'                   => '2.53',
        'Data::Validate::URI'    => '0.06',
        'Data::Validate::Domain' => '0.10',
        'WWW::Google::UserAgent' => '0.20',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-URLShortener-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::URLShortener'                    => { file => 'lib/WWW/Google/Shortener.pm'                 , version => '0.22' },
            'WWW::Google::URLShortener::Params'            => { file => 'lib/WWW/Google/Shortener/Params.pm'          , version => '0.22' },
            'WWW::Google::URLShortener::Analytics'         => { file => 'lib/WWW/Google/Shortener/Analytics.pm'       , version => '0.22' },
            'WWW::Google::URLShortener::Analytics::Result' => { file => 'lib/WWW/Google/Shortener/Analytics/Result.pm', version => '0.22' },
            'WWW::Google::URLShortener::Analytics::Result::Country'  => { file => 'lib/WWW/Google/Shortener/Analytics/Result/Country.pm' , version => '0.22' },
            'WWW::Google::URLShortener::Analytics::Result::Browser'  => { file => 'lib/WWW/Google/Shortener/Analytics/Result/Browser.pm' , version => '0.22' },
            'WWW::Google::URLShortener::Analytics::Result::Referrer' => { file => 'lib/WWW/Google/Shortener/Analytics/Result/Referrer.pm', version => '0.22' },
            'WWW::Google::URLShortener::Analytics::Result::Platform' => { file => 'lib/WWW/Google/Shortener/Analytics/Result/Platform.pm', version => '0.22' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-URLShortener.git',
                web  => 'https://github.com/manwar/WWW-Google-URLShortener',
            },
        }})
     : ()
    ),
);
