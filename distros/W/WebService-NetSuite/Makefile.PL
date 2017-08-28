#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %config = (
    NAME          => 'WebService::NetSuite',
    AUTHOR        => 'Fred Moyer <fred@redhotpenguin.com>',
    VERSION_FROM  => 'lib/WebService/NetSuite.pm',
    ABSTRACT_FROM => 'lib/WebService/NetSuite.pm',
    PREREQ_PM     => {
        'SOAP::Lite'            => 1.05,
        'XML::Parser'           => 0,
        'XML::Parser::EasyTree' => 0,
        'Carp'                  => 0,
        'Data::Dumper'          => 0,
        'Crypt::OpenSSL::RSA'   => 0,
    },
);

WriteMakefile(%config);
