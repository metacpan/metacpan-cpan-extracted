#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'XMLRPC-Lite',
    VERSION_FROM => 'lib/XMLRPC/Lite.pm',
    PREREQ_PM    => {
        'SOAP::Lite'           => 0.716,
        'SOAP::Transport::TCP' => 0.715
    },
    ABSTRACT_FROM => 'lib/XMLRPC/Lite.pm',
    AUTHOR        => 'Paul Kulchenko (paulclinger@yahoo.com)'
);
