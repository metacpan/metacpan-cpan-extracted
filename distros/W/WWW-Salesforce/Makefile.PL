#!/usr/bin/env perl

use strict;
use warnings;

use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::Salesforce',
    VERSION_FROM      => 'lib/WWW/Salesforce.pm',
    ABSTRACT_FROM => 'lib/WWW/Salesforce.pm',
    AUTHOR => 'Fred Moyer <fred@redhotpenguin.com>',
    LICENSE => 'artistic_2',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
    },
    PREREQ_PM         => {
        'Crypt::SSLeay' => 0.56,
        'SOAP::Lite'    => 0.68,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            license => 'http://www.opensource.org/licenses/artistic-license-2.0',
            homepage => 'https://github.com/redhotpenguin/WWW-Salesforce',
            bugtracker => 'https://github.com/redhotpenguin/WWW-Salesforce/issues',
            repository => {
                type => 'git',
                url  => 'https://github.com/redhotpenguin/WWW-Salesforce.git',
                web  => 'https://github.com/redhotpenguin/WWW-Salesforce',
            },
        },
        no_index => {directory => ['t',]},
    },
    test => {TESTS => 't/*.t'},
);
