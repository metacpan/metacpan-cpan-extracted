#!/usr/bin/perl
use 5.030;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::Hexonet::Connector',
    VERSION_FROM => 'lib/WebService/Hexonet/Connector.pm',
    PREREQ_PM    => {
        'LWP::Protocol::https' => 6.07,
        'LWP::UserAgent'       => 6.46,
        'Time::Local'          => 0,
        'MIME::Base64'         => 0,
        'Data::Dumper'         => 0,
        'utf8'                 => 0,
        'Readonly'             => 2.05,
        'Carp'                 => 0,
        'POSIX'                => 0,
        'List::MoreUtils'      => 0.428,
        'version'              => 0.9924,
        'Config'               => 0
    },
    TEST_REQUIRES => {
        'Test::More'             => 0,
        'Test::Exception'        => 0,
        'Test::RequiresInternet' => 0,
        'Scalar::Util'           => 0,
        'Readonly'               => 0,
        'version'                => 0,
        'POSIX'                  => 0,
        'Config'                 => 0
    },
    ABSTRACT_FROM    => 'lib/WebService/Hexonet/Connector.pm',
    AUTHOR           => 'hexonet <middleware@hexonet.net>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.030000'
);

1;
