#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService::Salesforce::Message',
    VERSION_FROM  => 'lib/WebService/Salesforce/Message.pm',
    PREREQ_PM     => { 'Moo' => 0, 'XML::LibXML' => 0 },
    ABSTRACT_FROM => 'lib/WebService/Salesforce/Message.pm',
    AUTHOR        => 'Fred Moyer <fred@redhotpenguin.com>',
);
