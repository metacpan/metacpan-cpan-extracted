#!/usr/bin/env perl

use 5.008008;
use strict;
use warnings;
 
use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME          => 'WebService::Gyazo',
    AUTHOR        => 'MaximusFox <shok@cpan.org>',
    LICENSE       => 'perl_5',
    VERSION_FROM  => 'lib/WebService/Gyazo.pm',
    #ABSTRACT_FROM => 'lib/WebService/Gyazo.pm',
    PREREQ_PM     => {
        'LWP::UserAgent' => 0,
        'LWP::Protocol::socks' => 0,
        'HTTP::Request::Common' => 0,
        'URI::Simple' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.88,
        'Test::Pod'  => 0,
        'Test::Pod::Coverage' => 0,
    },
    META_MERGE   => {
      requires  => { perl => '5.008008' },
      resources => {
        homepage    => 'https://github.com/maximusfox/WebService--Gyazo',
        license     => 'http://dev.perl.org/licenses/',
        repository  => 'https://github.com/maximusfox/WebService--Gyazo',
        bugtracker  => 'https://github.com/maximusfox/WebService--Gyazo/issues'
      },
    }
);